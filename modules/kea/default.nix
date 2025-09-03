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
      pool = mkOption {
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
      pool = mkOption {
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

    IPXE = mkOption {
      default = true;
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
          allowedUDPPorts = [53 67 69 547 5353];
          allowedTCPPorts = [80];
        };
      })
      cfg.networks;

    # networking.nat = mkIf cfg.IPMasquerade {
    #   enable = true;
    #   internalInterfaces = mapAttrsToList (_: network: network.interface) cfg.networks;
    #   externalInterface = "br0";
    #   enableIPv6 = true;
    # };

    networking.firewall.allowPing = true;

    services.dnsmasq = {
      enable = true;
      settings = let
        address = (mapAttrsToList (_: network: "${network.ipv4.address}") cfg.networks) ++ (mapAttrsToList (_: network: "${network.ipv6.address}") cfg.networks);
      in {
        interface = concatMapStringsSep "," (network: "${network.interface}") (attrValues cfg.networks);
        enable-tftp = true;
        dhcp-range = (mapAttrsToList (_: network: "interface:${network.interface},${network.ipv4.pool}") cfg.networks) ++ (mapAttrsToList (_: network: "${network.ipv6.pool},constructor:${network.interface},ra-stateless") cfg.networks);
        listen-address = concatStringsSep "," address;
        dhcp-option = (mapAttrsToList (_: network: "interface:${network.interface},6,${network.ipv4.address}") cfg.networks) ++ (mapAttrsToList (_: network: "interface:${network.interface},option6:dns-server,[${network.ipv6.address}]") cfg.networks);
        bind-interfaces = true;
        log-dhcp = true;
        tftp-root = "/etc/ipxe";
        dhcp-match = "set:ipxe,175";
        dhcp-boot = ["tag:!ipxe,ipxe.efi" "tag:ipxe,boot.ipxe"];
        port = 0;
      };
    };

    services.resolved = {
      extraConfig = ''
        MulticastDNS=yes
        ${concatMapStringsSep "\n" (network: ''
          DNSStubListenerExtra=${network.ipv4.address}
          DNSStubListenerExtra=${network.ipv6.address}
        '') (attrValues cfg.networks)}
      '';
      enable = true;
    };

    systemd.network.networks = listToAttrs (forEach (attrValues cfg.networks) (network: {
      name = "50-${network.interface}";
      value = {
        matchConfig.Name = "${network.interface}";
        bridgeConfig = {};
        networkConfig = {
          Address = ["${network.ipv4.address}/${network.ipv4.netmask}" "${network.ipv6.address}/${network.ipv6.netmask}"];
          IPMasquerade = "both";
          ConfigureWithoutCarrier = true;
          IPv6AcceptRA = false;
          IPv6PrivacyExtensions = "no";
          MulticastDNS = true;
          Domains = ["local"];
        };
        linkConfig = {
          # or "routable" with IP addresses configured
          ActivationPolicy = "always-up";
          RequiredForOnline = "no";
          Multicast = true;
          MTUBytes = "9000";
        };
      };
    }));
  };
}
