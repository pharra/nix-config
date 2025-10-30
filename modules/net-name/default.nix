{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.net-name;
in {
  options.net-name = {
    enable = mkEnableOption "net name";

    interfaces = lib.mkOption {
      type = types.listOf (
        types.submodule {
          options.mac = mkOption {
            type = types.str;
          };

          options.name = mkOption {
            type = types.str;
          };
        }
      );
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    boot.initrd = {
      services.udev.rules = concatMapStringsSep "\n" (interface: "ACTION==\"add\", SUBSYSTEM==\"net\", ATTR{address}==\"${interface.mac}\", NAME=\"${interface.name}\", ATTR{power/control}=\"on\"") cfg.interfaces;
    };

    services.udev.extraRules = concatMapStringsSep "\n" (interface: "ACTION==\"add\", SUBSYSTEM==\"net\", ATTR{address}==\"${interface.mac}\", NAME=\"${interface.name}\", ATTR{power/control}=\"on\"") cfg.interfaces;
  };
}
