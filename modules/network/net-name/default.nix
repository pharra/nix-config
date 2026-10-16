{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.services.pharra.net-name;
in {
  options.services.pharra.net-name = {
    enable = mkEnableOption "net name";

    interfaces = lib.mkOption {
      description = "按 MAC 给网卡改名的列表";
      type = types.listOf (
        types.submodule {
          options.mac = mkOption {
            description = "网卡 MAC 地址";
            type = types.str;
          };

          options.name = mkOption {
            description = "希望改成的接口名";
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
