{
  pkgs,
  username,
  config,
  ...
}: {
  programs = {
    zsh.enable = true;
  };
  programs.niri.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --asterisks --remember --remember-session --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
      };
    };
  };

  qt = {
    enable = true;
    style = "breeze";
    platformTheme = "qt5ct";
  };

  services.noctalia-shell.enable = true;

  fonts.packages = with pkgs; [
    # Niri fonts
    inter
    roboto
  ];

  environment.systemPackages = with pkgs; [
    fuzzel
    vesktop
    webcord
    kitty
    fastfetch
    alacritty

    gpu-screen-recorder
    brightnessctl
    ddcutil
    cliphist
    matugen
    cava
    wlsunset
    kdePackages.polkit-kde-agent-1
    evolution-data-server
  ];
}
