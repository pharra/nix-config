{
  pkgs,
  username,
  ...
}: {
  programs = {
    zsh.enable = true;
    dconf.enable = true;
  };

  services = {
    xserver = {
      enable = true;

      layout = "us"; # Keyboard layout & €-sign
      libinput.enable = true;

      displayManager.sddm.enable = true; # Display Manager
      #displayManager.sddm.autoLogin.relogin = true;
      desktopManager.plasma5.enable = true; # Window Manager
      displayManager.autoLogin = {
        enable = true;
        user = "${username}";
      };
    };
  };

  hardware.pulseaudio.enable = false;

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
