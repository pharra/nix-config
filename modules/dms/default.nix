{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.pharra.dms;
in {
  options = {
    services.pharra.dms = {
      enable = mkEnableOption "DankMaterialShell with Niri desktop environment";
    };
  };

  config = mkIf cfg.enable {
    programs = {
      niri.enable = true;

      dms-shell = {
        enable = true;
        systemd = {
          enable = true;
          target = "graphical-session.target";
          restartIfChanged = true;
        };

        plugins = {
          # Simply enable plugins by their ID (from the registry)
          linuxWallpaperEngine.enable = true; # Wallpaper engine for Linux (linux-wallpaper-engine)
        };
        enableSystemMonitoring = true; # System monitoring widgets (dgop)
        enableVPN = true; # VPN management widget
        enableDynamicTheming = true; # Wallpaper-based theming (matugen)
        enableAudioWavelength = true; # Audio visualizer (cava)
        enableCalendarEvents = true; # Calendar integration (khal)
        enableClipboardPaste = true; # Pasting from the clipboard history (wtype)
      };
    };

    services.displayManager.dms-greeter = {
      enable = true;
      compositor.name = "niri"; # Or "hyprland" or "sway"
    };

    environment.sessionVariables = {
      TERMINAL = "foot";
    };

    environment.systemPackages = with pkgs; [
      alacritty
      linux-wallpaperengine

      # Wayland utilities
      wayland-utils
      wl-clipboard
      xwayland-satellite
    ];

    services.pulseaudio.enable = false;
  };
}
