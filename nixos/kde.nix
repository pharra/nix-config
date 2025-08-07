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
    # xserver = {
    #   enable = true;

    #   xkb.layout = "us"; # Keyboard layout & €-sign
    #   libinput.enable = true;
    # };
    displayManager.sddm.enable = true; # Display Manager
    #displayManager.sddm.autoLogin.relogin = true;
    displayManager.sddm.wayland.enable = true;
    displayManager.sddm.enableHidpi = true;
    displayManager.sessionPackages = [pkgs.distrobox-session];
    desktopManager.plasma6.enable = true; # Window Manager
    # displayManager.autoLogin = {
    #   enable = true;
    #   user = "${username}";
    # };
  };

  environment.systemPackages = with pkgs; [
    kdePackages.kirigami
    kdePackages.wallpaper-engine-plugin
    attic-client
  ];

  i18n.inputMethod = {
    fcitx5.plasma6Support = true;
  };

  services.pulseaudio.enable = false;
}
