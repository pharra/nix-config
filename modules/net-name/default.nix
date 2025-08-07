{
  lib,
  pkgs,
  config,
  pkgs-2305,
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
      systemd.initrdBin = [pkgs.iputils pkgs.coreutils];
      systemd.services.ensure-network = {
        enable = true;
        before = ["network-online.target"];
        wantedBy = ["network-online.target"];
        after = ["nss-lookup.target"];
        unitConfig = {
          DefaultDependencies = "no";
        };
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = "yes";
          ExecStart = "${pkgs.bashInteractive}/bin/sh -c 'until ${pkgs.iputils}/bin/ping -c 1 1.1.1.1; do ${pkgs.coreutils}/bin/sleep 1; done'";
        };
      };

      services.udev.rules = concatMapStringsSep "\n" (interface: "ACTION==\"add\", SUBSYSTEM==\"net\", ATTR{address}==\"${interface.mac}\", NAME=\"${interface.name}\" ATTR{power/control}=\"on\"") cfg.interfaces;
    };

    services.udev.extraRules = concatMapStringsSep "\n" (interface: "ACTION==\"add\", SUBSYSTEM==\"net\", ATTR{address}==\"${interface.mac}\", NAME=\"${interface.name}\" ATTR{power/control}=\"on\"") cfg.interfaces;
  };
}
