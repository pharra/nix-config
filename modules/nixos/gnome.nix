{pkgs, ...}: {
  programs = {
    zsh.enable = true;
    dconf.enable = true;
    kdeconnect = {
      # For GSConnect
      enable = true;
      package = pkgs.gnomeExtensions.gsconnect;
    };
  };

  services = {
    xserver = {
      enable = true;

      layout = "us"; # Keyboard layout & €-sign
      libinput.enable = true;

      displayManager.gdm.enable = true; # Display Manager
      desktopManager.gnome.enable = true; # Window Manager
    };
    udev.packages = with pkgs; [
      gnome.gnome-settings-daemon
    ];
  };

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
        gedit
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
}
