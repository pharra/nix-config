{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.network-bridge;
in {
  options.services.network-bridge = {
    enable = mkEnableOption "network bridge configuration";

    bridges = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Bridge interface name (e.g., br0, br1)";
          };

          ports = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "List of interfaces to add as bridge ports";
          };

          configureNetwork = mkOption {
            type = types.bool;
            default = true;
            description = "Configure network settings for this bridge interface";
          };

          dhcp = mkOption {
            type = types.bool;
            default = true;
            description = "Enable DHCP on the bridge";
          };

          ipv6AcceptRA = mkOption {
            type = types.bool;
            default = true;
            description = "Accept Router Advertisements for IPv6 SLAAC";
          };

          domains = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "DNS domains for this bridge";
          };
        };
      });
      default = {};
      description = "Bridge configurations";
    };
  };

  config = mkIf cfg.enable {
    systemd.network = {
      enable = true;
      wait-online.anyInterface = true;

      netdevs =
        lib.mapAttrs' (
          bridgeName: bridgeCfg:
            lib.nameValuePair "20-${bridgeCfg.name}" {
              netdevConfig = {
                Kind = "bridge";
                Name = bridgeCfg.name;
              };
            }
        )
        cfg.bridges;

      networks =
        # Create networks for bridge ports
        (lib.foldl (
            acc: bridgeName: let
              bridgeCfg = cfg.bridges.${bridgeName};
            in
              acc
              // lib.listToAttrs (lib.imap0 (
                  idx: port:
                    lib.nameValuePair "30-${port}" {
                      matchConfig.Name = port;
                      networkConfig.Bridge = bridgeCfg.name;
                      linkConfig.RequiredForOnline = "enslaved";
                    }
                )
                bridgeCfg.ports)
          ) {}
          (builtins.attrNames cfg.bridges))
        # Create networks for bridge interfaces
        // (lib.foldl (
            acc: bridgeName: let
              bridgeCfg = cfg.bridges.${bridgeName};
            in
              if bridgeCfg.configureNetwork
              then
                acc
                // {
                  "40-${bridgeCfg.name}" = {
                    matchConfig.Name = bridgeCfg.name;
                    bridgeConfig = {};
                    networkConfig =
                      {
                        Domains = bridgeCfg.domains;
                      }
                      // lib.optionalAttrs bridgeCfg.dhcp {
                        DHCP = "ipv4";
                      }
                      // lib.optionalAttrs bridgeCfg.ipv6AcceptRA {
                        IPv6AcceptRA = true;
                      };
                    dhcpV4Config = lib.optionalAttrs bridgeCfg.dhcp {
                      UseDomains = true;
                    };
                    ipv6AcceptRAConfig = lib.optionalAttrs bridgeCfg.ipv6AcceptRA {
                      UseDNS = true;
                      UseDomains = true;
                    };
                    linkConfig = lib.optionalAttrs bridgeCfg.dhcp {
                      RequiredForOnline = "routable";
                    };
                  };
                }
              else acc
          ) {}
          (builtins.attrNames cfg.bridges));
    };
  };
}
