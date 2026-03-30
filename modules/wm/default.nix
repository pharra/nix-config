{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.pharra.desktopShell;
in {
  options = {
    services.pharra.desktopShell = {
      enable = mkEnableOption "Desktop shell integration for Wayland sessions";

      variant = mkOption {
        type = types.enum ["dms" "noctalia"];
        default = "dms";
        description = "Desktop shell variant to launch (dms or noctalia).";
      };

      compositor = mkOption {
        type = types.enum ["niri" "hyprland"];
        default = "niri";
        description = "The Wayland compositor to use with this shell profile (niri or hyprland).";
      };
    };
  };

  config = mkIf cfg.enable {
    programs = {
      niri.enable = cfg.compositor == "niri";
      hyprland.enable = cfg.compositor == "hyprland";

      dms-shell = mkIf (cfg.variant == "dms") {
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

    services.noctalia-shell = mkIf (cfg.variant == "noctalia") {
      enable = true;
    };

    services.displayManager.dms-greeter = {
      enable = true;
      compositor.name = cfg.compositor;
    };

    environment.systemPackages = with pkgs; [
      alacritty
      linux-wallpaperengine
      papirus-icon-theme
      kdePackages.dolphin
      kdePackages.gwenview

      # Wayland utilities
      wayland-utils
      wl-clipboard
      xwayland-satellite
    ];
  };
}
