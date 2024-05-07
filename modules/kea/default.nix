{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.keaWithDDNS;

  forward = upstream: let
    inherit (upstream) method zone;
    inherit (upstream) tls udp;
  in
    getAttr method {
      tls = ''
        forward ${zone} tls://${tls.ip} {
          tls_servername ${tls.servername}
          health_check 1h
        }
      '';

      udp = ''
        forward ${zone} ${udp.ip} {
          health_check 1h
        }
      '';

      "resolv.conf" = ''
        forward ${zone} /etc/resolv.conf
      '';
    };

  ipv4Options = {
    options = {
      subnet = mkOption {
        type = types.str;
      };
      address = mkOption {
        type = types.str;
      };
      netmask = mkOption {
        type = types.str;
      };
      pools = mkOption {
        type = types.listOf types.str;
      };
      broadcast = mkOption {
        type = types.str;
      };
      reservations = mkOption {
        type = types.listOf (
          types.submodule {
            options.hw-address = mkOption {
              type = types.str;
              description = "MAC address of the host";
            };

            options.ip-address = mkOption {
              type = types.nullOr types.str;
              description = "IP address to assign to the host";
              default = null;
            };

            options.hostname = mkOption {
              type = types.str;
              description = "IP address to assign to the host";
            };
          }
        );

        description = "Static DHCP reservations";
        default = [];
      };
    };
  };

  ipv6Options = {
    options = {
      subnet = mkOption {
        type = types.str;
      };
      address = mkOption {
        type = types.str;
      };
      netmask = mkOption {
        type = types.str;
      };
      prefix = mkOption {
        type = types.str;
      };
      delegated-len = mkOption {
        type = types.str;
      };
      pools = mkOption {
        type = types.listOf types.str;
      };
      broadcast = mkOption {
        type = types.str;
      };
      id = mkOption {
        type = types.int;
      };
      reservations = mkOption {
        type = types.listOf (
          types.submodule {
            options.hw-address = mkOption {
              type = types.str;
              description = "MAC address of the host";
            };

            options.ip-addresses = mkOption {
              type = types.nullOr (types.listOf types.str);
              description = "IP addresses to assign to the host";
              default = null;
            };

            options.hostname = mkOption {
              type = types.str;
              description = "IP address to assign to the host";
            };
          }
        );

        description = "Static DHCP reservations";
        default = [];
      };
    };
  };

  networkOptions = {
    options = {
      name = mkOption {
        description = "Network name";
        type = types.str;
      };

      interface = mkOption {
        description = "Name of the network interface to use";
        type = types.str;
      };

      domain = mkOption {
        description = "Name of the domain";
        type = types.str;
      };

      ipv4 = mkOption {
        default = {};
        type = types.submodule ipv4Options;
      };

      ipv6 = mkOption {
        default = {};
        type = types.submodule ipv6Options;
      };
    };
  };
in {
  options.services.keaWithDDNS = {
    enable = mkEnableOption "Run a DHCP server";

    IPMasquerade = mkOption {
      default = false;
      type = types.bool;
    };

    onlySLAAC = mkOption {
      default = false;
      type = types.bool;
    };

    networks = mkOption {
      description = "Map of networks";
      default = {};
      type = types.attrsOf (types.submodule networkOptions);
    };

    DNSForward = mkOption {
      default = [];
      description = ''
        Forward DNS queries to other DNS servers. This is useful for resolving
        external domains or for using a DNS-over-TLS service.

        ORDER MATTERS. The first matching zone is used even if a more specific
        zone is later in the list.
      '';

      type = types.listOf (
        types.submodule {
          options.zone = mkOption {
            type = types.str;
            description = ''
              The domain pattern being forwarded. Use <literal>.</literal> to
              match all queries.
            '';
          };

          options.method = mkOption {
            type = types.enum [
              "tls"
              "udp"
              "resolv.conf"
            ];

            default = "tls";
            description = ''
              Method used to resolve queries for this zone. TLS is
              recommended.
            '';
          };

          options.tls = {
            ip = mkOption {
              type = types.str;
              description = "IP address of the DNS server";
            };

            servername = mkOption {
              type = types.str;
              description = "Hostname used for session validation";
            };
          };

          options.udp.ip = mkOption {
            type = types.str;
            description = "IP address of the DNS server";
          };
        }
      );
    };
  };

  config = mkIf cfg.enable {
    # Open DHCP ports on participating LAN interfaces.
    networking.firewall.interfaces =
      mapAttrs' (_: network: {
        name = network.interface;
        value = {
          allowedUDPPorts = [67 53 547];
        };
      })
      cfg.networks;

    networking.nat = mkIf cfg.IPMasquerade {
      enable = true;
      internalInterfaces = mapAttrsToList (_: network: network.interface) cfg.networks;
      externalInterface = "br0";
      enableIPv6 = true;
    };

    # networking = {
    #   # Ignore advertised DNS servers and resolve queries locally. In HA
    #   # setups, other nameservers may be unresponsive.
    #   nameservers = ["127.0.0.1"];
    # };

    services.coredns = {
      enable = true;

      config = ''
        (common) {
          bind ${toString (["lo"] ++ mapAttrsToList (_: network: network.interface) cfg.networks)}

          log
          errors
          local

          nsid
        }

        . {
          import common
          cache

          # Upstream DNS servers
          ${concatMapStringsSep "\n" forward cfg.DNSForward}
        }
      '';
    };

    systemd.network.networks = listToAttrs (forEach (attrValues cfg.networks) (network: {
      name = "50-${network.interface}";
      value = {
        matchConfig.Name = "${network.interface}";
        bridgeConfig = {};
        networkConfig = {
          Address = ["${network.ipv4.address}/${network.ipv4.netmask}" "${network.ipv6.address}/${network.ipv6.netmask}"];
          IPMasquerade = "ipv4";
          ConfigureWithoutCarrier = true;
          # MulticastDNS = true;
        };
        linkConfig = {
          # or "routable" with IP addresses configured
          ActivationPolicy = "always-up";
          RequiredForOnline = "no";
        };
      };
    }));

    services.radvd = {
      enable = true;
      config = ''
        ${concatMapStringsSep "\n" (network: ''
          interface ${network.interface} {
            AdvSendAdvert on;
            MinRtrAdvInterval 30;
            MaxRtrAdvInterval 600;
            AdvManagedFlag ${
            if cfg.onlySLAAC
            then "off"
            else "on"
          };                   #M bit=1
            AdvOtherConfigFlag ${
            if cfg.onlySLAAC
            then "off"
            else "on"
          };               #O bit=1
            AdvLinkMTU 1500;
            AdvSourceLLAddress on;
            AdvDefaultPreference high;
            prefix ${network.ipv6.prefix}/${network.ipv6.delegated-len}
            {
              AdvOnLink on;
              AdvAutonomous on;                   #A bit=1
              AdvRouterAddr on;
              AdvPreferredLifetime 3600;
              AdvValidLifetime 7200;
            };
            # route ${network.ipv6.prefix}/${network.ipv6.delegated-len} {
            # };
            RDNSS ${network.ipv6.address}
            {
            };
          };
        '') (attrValues cfg.networks)}
      '';
    };

    services.kea = {
      dhcp4 = {
        enable = true;
        settings = {
          valid-lifetime = 3600;
          renew-timer = 900;
          rebind-timer = 1800;

          lease-database = {
            type = "memfile";
            persist = true;
            name = "/var/lib/kea/dhcp4.leases";
          };

          interfaces-config = {
            interfaces = mapAttrsToList (_: network: "${network.interface}/${network.ipv4.address}") cfg.networks;
          };

          subnet4 =
            mapAttrsToList (_: network: {
              interface = network.interface;
              subnet = network.ipv4.subnet;
              pools = forEach network.ipv4.pools (item: {
                pool = item;
              });
              ddns-qualifying-suffix = network.domain;
              reservations = network.ipv4.reservations;

              option-data = [
                {
                  name = "domain-name-servers";
                  data = network.ipv4.address;
                }
                {
                  name = "routers";
                  data = network.ipv4.address;
                }
              ];
            })
            cfg.networks;

          # dhcp-ddns = {
          #   enable-updates = true;
          #   server-ip = "127.0.0.1";
          #   server-port = 53001;
          # };
        };
      };

      dhcp6 = mkIf (! cfg.onlySLAAC) {
        enable = true;
        settings = {
          valid-lifetime = 3600;
          renew-timer = 900;
          rebind-timer = 1800;

          lease-database = {
            type = "memfile";
            persist = true;
            name = "/var/lib/kea/dhcp6.leases";
          };

          interfaces-config = {
            interfaces = mapAttrsToList (_: network: "${network.interface}/${network.ipv6.address}") cfg.networks;
          };

          # mac-sources = ["duid"];

          subnet6 =
            mapAttrsToList (_: network: {
              interface = network.interface;
              subnet = network.ipv6.subnet;
              pools = forEach network.ipv6.pools (item: {
                pool = item;
              });
              id = network.ipv6.id;
              # pd-pools = [
              #   {
              #     prefix = network.ipv6.prefix;
              #     prefix-len = lib.strings.toInt network.ipv6.netmask;
              #     delegated-len = lib.strings.toInt network.ipv6.delegated-len;
              #   }
              # ];
              ddns-qualifying-suffix = network.domain;
              reservations = network.ipv6.reservations;

              option-data = [
                {
                  name = "dns-servers";
                  data = network.ipv6.address;
                }
                # {
                #   name = "unicast";
                #   data = network.ipv6.address;
                # }
                # {
                #   name = "link-address";
                #   data = network.ipv6.address;
                # }
              ];
            })
            cfg.networks;

          # dhcp-ddns = {
          #   enable-updates = true;
          #   server-ip = "127.0.0.1";
          #   server-port = 53001;
          # };
        };
      };

      # dhcp-ddns = {
      #   enable = true;
      #   settings = {
      #     ip-address = "127.0.0.1";
      #     port = 53001;
      #     forward-ddns = {
      #       ddns-domains =
      #         mapAttrsToList (_: network: {
      #           name = network.domain;
      #           dns-servers = [
      #             {
      #               ip-address = network.ipv4.address;
      #               port = 53;
      #             }
      #             {
      #               ip-address = network.ipv6.address;
      #               port = 53;
      #             }
      #           ];
      #         })
      #         cfg.networks;
      #     };
      #     reverse-ddns = {
      #       ddns-domains = [];
      #     };
      #   };
      # };
    };
  };
}
