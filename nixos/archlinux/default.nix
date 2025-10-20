{
  pkgs,
  lib,
  config,
  utils,
  ...
}: {
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
}
