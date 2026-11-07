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

  # wm 的 shell 由 systemd 启动，不继承 niri/umbriel 的 environment 块；
  # DMS 和 noctalia 都注入同一组 fcitx5 变量，以后新增 wm variant 也复用。
  waylandImEnvironment = {
    XMODIFIERS = "@im=fcitx";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
  };
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
    services.pharra.kwallet-shim.enable = true;
    services.pharra.kwallet-shim.xdgCurrentDesktop =
      if (cfg.variant == "dms")
      then "niri:KDE"
      else if (cfg.variant == "noctalia")
      then "umbriel:KDE"
      else throw "Invalid desktop shell variant: ${cfg.variant}";

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

      dux-shell = mkIf (cfg.variant == "dms") {
        enable = true;
        systemd = {
          enable = true;
          target = "graphical-session.target";
          restartIfChanged = true;
        };
      };

      dux-files = mkIf (cfg.variant == "dms") {
        enable = true;
        systemd.enable = true;
        systemd.target = "graphical-session.target";
        portal.enable = true;
      };
      dux-search = mkIf (cfg.variant == "dms") {
        enable = true;
        systemd.enable = true;
        systemd.target = "graphical-session.target";
      };
      dux-calendar = mkIf (cfg.variant == "dms") {
        enable = true;
        systemd.enable = true;
        systemd.target = "graphical-session.target";
      };

      noctalia = mkIf (cfg.variant == "noctalia") {
        enable = true;

        systemd.enable = true;

        # Enables NetworkManager, Bluetooth, UPower, and a power profile service.
        recommendedServices.enable = true;
      };
    };

    # 让 DMS / noctalia 启动的应用也拿到 fcitx5 环境变量。
    systemd.user.services.dms.environment = mkIf (cfg.variant == "dms") waylandImEnvironment;
    systemd.user.services.noctalia.environment = mkIf (cfg.variant == "noctalia") waylandImEnvironment;

    services.displayManager.dux-greeter = mkIf (cfg.variant == "dms") {
      enable = true;
      compositor.name = cfg.compositor;
      configHome = "/home/${username}";
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

    # Work around niri#2435 logout breaking user services
    systemd.user.services.niri = mkIf (cfg.compositor == "niri") {
      serviceConfig.ExecStop = "${pkgs.systemd}/bin/systemctl --user stop graphical-session.target";
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
      "QT_QPA_PLATFORM" = "wayland";
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
