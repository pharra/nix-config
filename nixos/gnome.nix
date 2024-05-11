{
  pkgs,
  username,
  ...
}: {
  programs = {
    zsh.enable = true;
    dconf.enable = true;
    kdeconnect = {
      # For GSConnect
      enable = true;
      package = pkgs.gnomeExtensions.gsconnect;
    };
  };

  services.gnome.gnome-remote-desktop.enable = true;

  services = {
    libinput.enable = true;

    xserver = {
      enable = true;

      xkb.layout = "us"; # Keyboard layout & €-sign

      displayManager.gdm.enable = true; # Display Manager
      desktopManager.gnome.enable = true; # Window Manager

      # displayManager.defaultSession = "gnome";
      # displayManager.autoLogin = {
      #   enable = true;
      #   user = "${username}";
      # };
    };
    udev.packages = with pkgs; [
      gnome.gnome-settings-daemon
    ];
  };

  security.pam.services.gdm.enableGnomeKeyring = true;

  hardware.pulseaudio.enable = false;

  environment = {
    systemPackages = with pkgs; [
      # Packages installed
      gnome.dconf-editor
      gnome.gnome-tweaks
      gnome.adwaita-icon-theme
    ];
    gnome.excludePackages =
      (with pkgs; [
        # Gnome ignored packages
        gnome-tour
      ])
      ++ (with pkgs.gnome; [
        epiphany
        geary
        gnome-characters
        tali
        iagno
        hitori
        atomix
        yelp
        gnome-contacts
        gnome-initial-setup
      ]);
  };

  services.xserver.displayManager.gdm.autoSuspend = false;
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

  # For gnome autologin issue, see https://github.com/NixOS/nixpkgs/issues/103746
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
}
