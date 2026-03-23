{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.home.pharra.desktop;
in {
  options = {
    home.pharra.desktop = {
      enable = mkEnableOption "desktop home configuration";
    };
  };

  config = mkIf cfg.enable {
    # allow fontconfig to discover fonts and configurations installed through home.packages
    fonts.fontconfig.enable = true;

    programs = {
      firefox = {
        enable = true;
        enableGnomeExtensions = false;
      };
      vscode.enable = true;
    };

    home.packages = with pkgs; [
      # misc
      flameshot

      # XDG utils
      xdg-utils # provides cli tools such as `xdg-mime` `xdg-open`
      xdg-user-dirs
    ];

    # XDG configuration
    xdg = {
      enable = true;
      cacheHome = config.home.homeDirectory + "/.local/cache";

      userDirs = {
        enable = true;
        createDirectories = true;
        extraConfig = {
          SCREENSHOTS = "${config.xdg.userDirs.pictures}/Screenshots";
        };
      };
    };

    # Looking Glass configuration
    xdg.configFile."looking-glass/client.ini".text = lib.generators.toINI {} {
      app.shmFile = "/dev/kvmfr0";
      input.escapeKey = 100; # right alt
      win.fullScreen = "yes";
      win.jitRender = "yes";
      win.fpsMin = 120;
      audio.micDefault = "allow";
    };
  };
}
