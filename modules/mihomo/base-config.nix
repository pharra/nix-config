{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;
  format = pkgs.formats.yaml {};
  cfg = config.services.mihomo.config;
in {
  options.services.mihomo.config = mkOption {
    default = {};
    type = types.submodule {
      freeformType = format.type;
      options = {
        tun = {
          enable = mkOption {
            default = config.services.mihomo.tunMode;
            type = types.bool;
          };
          device = mkOption {
            default = "utun0";
            type = types.str;
          };
        };
      };
    };
  };

  config = {
    networking.firewall.trustedInterfaces = lib.mkIf config.services.mihomo.tunMode [cfg.tun.device];
    sops.templates."mihomo-config.yaml".content = builtins.toJSON cfg;
    services.mihomo.configFile = config.sops.templates."mihomo-config.yaml".path;
  };
}
