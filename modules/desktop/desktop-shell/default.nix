{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib; let
  cfg = config.services.pharra.desktop-shell;
  defaultNiriConfig = ./niri;
  defaultUmbrielConfig = ./umbriel;
  defaultDmsConfig = ./dank-material-shell;
  defaultNoctaliaConfig = ./noctalia-shell;
in {
  options = {
    services.pharra.desktop-shell = {
      enable = mkEnableOption "Desktop shell integration for Wayland sessions";

      variant = mkOption {
        type = types.enum ["dms" "noctalia"];
        default = "dms";
        description = "Desktop shell variant to launch (dms or noctalia).";
      };

      compositor = mkOption {
        type = types.enum ["niri" "umbriel"];
        description = "The Wayland compositor to use with this shell profile (niri or umbriel).";
      };
    };
  };

  config = mkIf cfg.enable {
    services.pharra.desktop-shell.compositor =
      if (cfg.variant == "dms")
      then "niri"
      else if (cfg.variant == "noctalia")
      then "umbriel"
      else throw "Invalid desktop shell variant: ${cfg.variant}";
    programs = {
      niri = mkIf (cfg.compositor == "niri") {
        enable = true;
        package = pkgs.niri-glass;
      };
      umbriel = mkIf (cfg.compositor == "umbriel") {
        enable = true;
      };

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
        enableVPN = true; # VPN management widget
        enableDynamicTheming = true; # Wallpaper-based theming (matugen)
        enableAudioWavelength = true; # Audio visualizer (cava)
        enableCalendarEvents = true; # Calendar integration (khal)
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

    environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json" = mkIf (cfg.compositor == "niri") {
      text = ''
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
    };

    services.displayManager.noctalia-greeter = mkIf (cfg.variant == "noctalia") {
      enable = true;

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

    services.xserver.displayManager.sessionCommands = ''
      ${pkgs.xorg.xrdb}/bin/xrdb -merge <<EOF
      Xft.dpi: 192
      EOF
    '';

    services.greetd = {
      settings = {
        terminal = {
          vt = lib.mkForce 7;
        };
      };
    };

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

    environment.sessionVariables = {
      "NIXOS_OZONE_WL" = "1";
      "MOZ_ENABLE_WAYLAND" = "1";
      "MOZ_WEBRENDER" = "1";
    };

    hjem.extraModules = [
      ({config, ...}:
        mkIf (config.user == username) {
          systemd.services.xembed-sni-proxy = {
            wantedBy = ["graphical-session.target"];
            partOf = ["graphical-session.target"];
            after = ["graphical-session.target"];
            serviceConfig = {
              ExecStart = "${pkgs.kdePackages.plasma-workspace}/bin/xembedsniproxy";
              Restart = "on-abort";
            };
          };

          systemd.services.install-desktop-defaults = {
            wantedBy = ["default.target"];
            serviceConfig.Type = "oneshot";
            script = ''
              copy_if_missing_dir() {
                src="$1"
                dst="$2"
                if [ -d "$src" ] && [ ! -e "$dst" ]; then
                  ${pkgs.coreutils}/bin/cp -r "$src" "$dst"
                fi
                if [ -d "$dst" ]; then
                  ${pkgs.coreutils}/bin/chmod -R u+w "$dst"
                fi
              }

              ${optionalString (cfg.compositor == "niri") ''
                copy_if_missing_dir "${defaultNiriConfig}" "$HOME/.config/niri"
              ''}

              ${optionalString (cfg.compositor == "umbriel") ''
                copy_if_missing_dir "${defaultUmbrielConfig}" "$HOME/.config/umbriel"
              ''}

              ${optionalString (cfg.variant == "dms") ''
                copy_if_missing_dir "${defaultDmsConfig}" "$HOME/.config/DankMaterialShell"
              ''}

              ${optionalString (cfg.variant == "noctalia") ''
                copy_if_missing_dir "${defaultNoctaliaConfig}" "$HOME/.config/noctalia"
              ''}
            '';
          };
        })
    ];
  };
}
