{
  pkgs,
  username,
  ...
}: {
  programs = {
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

    displayManager.gdm.enable = true; # Display Manager
    desktopManager.gnome.enable = true; # Window Manager
    udev.packages = with pkgs; [
      gnome-settings-daemon
    ];
  };

  security.pam.services.gdm.enableGnomeKeyring = true;

  services.pulseaudio.enable = false;

  environment = {
    systemPackages = with pkgs; [
      # Packages installed
      dconf-editor
      gnome-tweaks
      adwaita-icon-theme
    ];
    gnome.excludePackages = with pkgs; [
      # Gnome ignored packages
      gnome-tour
    ];
  };

  # For gnome autologin issue, see https://github.com/NixOS/nixpkgs/issues/103746
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
}
