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

  services.noctalia-shell.enable = true;

  environment.systemPackages = with pkgs; [
    fuzzel
    vesktop
    webcord
    kitty
    fastfetch
    alacritty
  ];
}
