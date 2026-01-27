{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.pharra.archlinux;
in {
  options = {
    services.pharra.archlinux = {
      enable = mkEnableOption "ArchLinux systemd-nspawn container";
    };
  };

  config = mkIf cfg.enable {
    systemd.nspawn.archlinux = {
      execConfig = {
        # Boot = true;
        # Timezone = "Bind";
        Hostname = "archlinux";
        PrivateUsers = "no";
      };
      enable = true;
      networkConfig = {
        MACVLAN = "br2";
      };
      filesConfig = {
        Bind = ["/dev/dri" "/dev/input" "/dev/uinput"];
      };
    };
  };
}
