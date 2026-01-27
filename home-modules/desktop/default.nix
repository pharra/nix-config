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
    home.packages = with pkgs; [
      # GUI apps
      insomnia # REST client
      wireshark # network analyzer

      # remote desktop(rdp connect)
      remmina
      freerdp # required by remmina

      # misc
      flameshot

      # XDG utils
      xdg-utils # provides cli tools such as `xdg-mime` `xdg-open`
      xdg-user-dirs
    ];

    # GitHub CLI tool
    programs.gh = {
      enable = true;
    };

    # XDG configuration
    xdg = {
      enable = true;
      cacheHome = config.home.homeDirectory + "/.local/cache";

      userDirs = {
        enable = true;
        createDirectories = true;
        extraConfig = {
          XDG_SCREENSHOTS_DIR = "${config.xdg.userDirs.pictures}/Screenshots";
        };
      };
    };

    # Looking Glass configuration
    xdg.configFile."looking-glass/client.ini".text = lib.generators.toINI {} {
      app.shmFile = "/dev/kvmfr0";
      input.escapeKey = 100; # key pause
      win.fullScreen = "yes";
      win.jitRender = "yes";
      win.fpsMin = 120;
      audio.micDefault = "allow";
    };
  };
}
