{
  pkgs,
  username,
  ...
}: {
  services = {
    xserver = {
      enable = true;

      # displayManager = {
      #   lightdm.enable = true;
      # };
      desktopManager.deepin.enable = true; # Window Manager

      displayManager.autoLogin = {
        enable = true;
        user = "${username}";
      };
    };
  };
}
