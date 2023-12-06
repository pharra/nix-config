{
  pkgs,
  username,
  ...
}: {
  programs = {
    zsh.enable = true;
    # dconf.enable = true;
  };

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

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.login1.suspend" ||
            action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
            action.id == "org.freedesktop.login1.hibernate" ||
            action.id == "org.freedesktop.login1.hibernate-multiple-sessions")
        {
            return polkit.Result.NO;
        }
    });
  '';
}
