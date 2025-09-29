{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.dhcpServer;

  # True values are just put as `name` instead of `name=true`, and false values
  # are turned to comments (false values are expected to be overrides e.g.
  # lib.mkForce)
  formatKeyValue = name: value:
    if value == true
    then name
    else if value == false
    then "# setting `${name}` explicitly set to false"
    else lib.generators.mkKeyValueDefault {} "=" name value;

  settingsFormat = pkgs.formats.keyValue {
    mkKeyValue = formatKeyValue;
    listsAsDuplicateKeys = true;
  };

  ipOptions = {
    options = {
      address = mkOption {
        type = types.str;
      };
      netmask = mkOption {
        type = types.str;
      };
      pool = mkOption {
        type = types.str;
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
        type = types.submodule ipOptions;
      };

      ipv6 = mkOption {
        default = {};
        type = types.submodule ipOptions;
      };
    };
  };
in {
  options.services.dhcpServer = {
    enable = mkEnableOption "Run a DHCP server";
    # IPXE = mkOption {
    #   default = true;
    #   type = types.bool;
    # };

    # onlySLAAC = mkOption {
    #   default = false;
    #   type = types.bool;
    # };

    networks = mkOption {
      description = "Map of networks";
      default = {};
      type = types.attrsOf (types.submodule networkOptions);
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

    networking.firewall.allowPing = true;

    boot.kernel.sysctl."net.ipv4.ip_forward" = "1";
    boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = "1";

    # Dnsmasq is used as the DHCP server.
    users.users.dnsmasq = {
      isSystemUser = true;
      group = "dnsmasq";
      description = "Dnsmasq daemon user";
    };
    users.groups.dnsmasq = {};
    systemd.services = listToAttrs (forEach (attrValues cfg.networks) (
      network: let
        iface = network.interface;
        stateDir = "/var/lib/dnsmasq-${iface}";
        dnsmasqConf = settingsFormat.generate "dnsmasq-${iface}.conf" {
          interface = [iface];
          enable-tftp = true;
          dhcp-range = [
            "interface:${iface},${network.ipv4.pool}"
            "${network.ipv6.pool},constructor:${iface},ra-stateless"
          ];
          listen-address = "${network.ipv4.address},${network.ipv6.address}";
          dhcp-option = [
            "interface:${iface},6,${network.ipv4.address}"
            "interface:${iface},option6:dns-server,[${network.ipv6.address}]"
          ];
          except-interface = ["lo"];
          bind-interfaces = true;
          log-dhcp = true;
          tftp-root = "/etc/ipxe";
          dhcp-match = "set:ipxe,175";
          dhcp-boot = ["tag:!ipxe,ipxe.efi" "tag:ipxe,boot.ipxe"];
          dhcp-leasefile = "${stateDir}/dnsmasq-${iface}.leases";
          local = "/${network.domain}/";
          domain = network.domain;
          expand-hosts = true;
          no-hosts = true;
          server = "114.114.114.114";
          host-record = ["homelab,homelab.${network.domain},${network.ipv4.address},${network.ipv6.address}"];
        };
      in {
        name = "dnsmasq-${iface}";
        value = {
          description = "Dnsmasq Daemon for ${iface}";
          after = [
            "network.target"
            "systemd-resolved.service"
          ];
          wantedBy = ["multi-user.target"];
          path = [pkgs.dnsmasq];
          preStart = ''
            mkdir -m 755 -p ${stateDir}
            touch ${stateDir}/dnsmasq-${iface}.leases
            chown -R dnsmasq ${stateDir}
            ${pkgs.dnsmasq}/bin/dnsmasq --test -C ${dnsmasqConf}
          '';
          serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.dnsmasq}/bin/dnsmasq -k --user=dnsmasq -C ${dnsmasqConf} -x /run/dnsmasq-${iface}.pid";
            PrivateTmp = true;
            ProtectSystem = true;
            ProtectHome = true;
            Restart = "on-failure";
          };
          restartTriggers = [config.environment.etc.hosts.source];
        };
      }
    ));

    systemd.network.networks = listToAttrs (forEach (attrValues cfg.networks) (network: {
      name = "50-${network.interface}";
      value = {
        matchConfig.Name = "${network.interface}";
        bridgeConfig = {};
        networkConfig = {
          Address = ["${network.ipv4.address}/${network.ipv4.netmask}" "${network.ipv6.address}/${network.ipv6.netmask}"];
          DNS = ["${network.ipv4.address}" "${network.ipv6.address}"];
          IPMasquerade = "both";
          ConfigureWithoutCarrier = true;
          IPv6AcceptRA = false;
          IPv6PrivacyExtensions = "no";
          Domains = ["${network.domain}"];
        };
        linkConfig = {
          # or "routable" with IP addresses configured
          # ActivationPolicy = "always-up";
          RequiredForOnline = "no";
          # MTUBytes = "9000";
        };
      };
    }));
  };
}
