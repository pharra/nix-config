{
  config,
  lib,
  pkgs,
  username,
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
      niri = mkIf (cfg.compositor == "niri") {
        enable = true;
        package = pkgs.niri-glass;
      };
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

      noctalia = mkIf (cfg.variant == "noctalia") {
        enable = true;

        systemd.enable = true;

        # Enables NetworkManager, Bluetooth, UPower, and a power profile service.
        recommendedServices.enable = true;
      };
    };

    services.displayManager.dms-greeter = mkIf (cfg.variant == "dms") {
      enable = true;
      compositor.name = cfg.compositor;
      configHome = "/home/${username}";
    };

    environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json".text = mkIf (cfg.compositor == "niri") ''
      {
        "rules": [
          {
            "pattern": {
              "feature": "procname",
              "matches": "niri"
            },
            "profile": "Limit Free Buffer Pool On Wayland Compositors"
          }
        ],
        "profiles": [
          {
            "name": "Limit Free Buffer Pool On Wayland Compositors",
            "settings": [
              {
                "key": "GLVidHeapReuseRatio",
                "value": 0
              }
            ]
          }
        ]
      }
    '';

    programs.noctalia-greeter = mkIf (cfg.variant == "noctalia") {
      enable = true;

      # Optional configuration
      greeter-args = "";
      settings = {
        cursor = {
          theme = "Bibata-Modern-Ice";
          size = 24;
          path = "${pkgs.bibata-cursors}/share/icons";
        };
        keyboard = {
          layout = "us";
        };
      };
    };

    # enable trash support for nautilus
    services.gvfs.enable = true;

    environment.systemPackages = with pkgs; [
      alacritty
      linux-wallpaperengine
      nautilus
      papirus-icon-theme
      kdePackages.gwenview
      kdePackages.qt6ct

      # Wayland utilities
      wayland-utils
      wl-clipboard
      xwayland-satellite
      i2c-tools
    ];
  };
}
