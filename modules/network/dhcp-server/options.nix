# 选项声明：ipOptions / staticHostOptions / networkOptions 三个子模块选项集，
# 以及 services.pharra.dhcp-server.* 的入口。
{lib, ...}:
with lib; let
  ipOptions = {
    options = {
      enable = mkOption {
        description = "Enable this IP configuration";
        type = types.bool;
        default = true;
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
    };
  };

  staticHostOptions = {
    options = {
      mac = mkOption {
        description = "MAC address";
        type = types.str;
        example = "aa:bb:cc:dd:ee:ff";
      };

      ip = mkOption {
        description = "Static IP address to assign";
        type = types.str;
        example = "192.168.1.100";
      };

      hostname = mkOption {
        description = "Hostname for the static host";
        type = types.nullOr types.str;
        default = null;
        example = "my-device";
      };
    };
  };

  networkOptions = {
    options = {
      name = mkOption {
        description = "Network name";
        type = types.str;
      };

      enableDnsmasq = mkOption {
        description = "Enable Dnsmasq for this network";
        type = types.bool;
        default = true;
      };

      masquerade = mkOption {
        description = "IP Masquerade";
        type = types.str;
        default = "no";
      };

      emitRoute = mkOption {
        description = "Emit DHCP default route (dnsmasq dhcp-option 3 and option6:6)";
        type = types.bool;
        default = false;
      };

      leaseTime = mkOption {
        description = "DHCP lease time for this network (dnsmasq dhcp-range lease time)";
        type = types.str;
        default = "24h";
        example = "12h";
      };

      interface = mkOption {
        description = "Name of the network interface to use";
        type = types.str;
      };

      domain = mkOption {
        description = "Name of the domain";
        type = types.str;
      };

      staticHosts = mkOption {
        description = "Static DHCP host assignments based on MAC address";
        default = [];
        type = types.listOf (types.submodule staticHostOptions);
        example = [
          {
            mac = "aa:bb:cc:dd:ee:ff";
            ip = "192.168.1.100";
            hostname = "my-device";
          }
        ];
      };

      boot = mkOption {
        description = "Optional PXE/iPXE boot configuration for this network";
        default = {};
        type = types.submodule {
          options = {
            tftp = {
              enable = mkEnableOption "TFTP server for PXE/iPXE";
              root = mkOption {
                type = types.str;
                default = "/etc/ipxe";
                description = "TFTP root directory";
              };
            };

            dhcpMatch = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "dnsmasq dhcp-match entries";
              example = ["set:ipxe,175"];
            };

            dhcpBoot = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "dnsmasq dhcp-boot entries";
              example = [
                "tag:!ipxe,snponly.efi"
                "tag:ipxe,boot.ipxe"
              ];
            };
          };
        };
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
  options.services.pharra.dhcp-server = {
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
}
