{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib; let
  cfg = config.services.pharra.dms;
  defaultNiriConfig = ./niri;
  defaultDmsConfig = ./dms;

  # wm 的 shell 由 systemd 启动，不继承 niri 的 environment 块；
  # DMS 的 service 注入同一组 fcitx5 变量。
  waylandImEnvironment = {
    XMODIFIERS = "@im=fcitx";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
  };
in {
  options = {
    services.pharra.dms = {
      enable = mkEnableOption "DMS Wayland desktop shell";
    };
  };

  config = mkIf cfg.enable {
    services.pharra.kwallet-shim.enable = true;
    services.pharra.kwallet-shim.xdgCurrentDesktop = "niri:KDE";

    programs = {
      niri = {
        enable = true;
        package = pkgs.niri-glass;
      };

      dux-shell = {
        enable = true;
        systemd = {
          enable = true;
          target = "graphical-session.target";
          restartIfChanged = true;
        };
        plugins = {
          linuxWallpaperEngine.enable = true;
        };
      };

      dux-files = {
        enable = true;
        systemd.enable = true;
        systemd.target = "graphical-session.target";
        portal.enable = true;
      };
      dux-search = {
        enable = true;
        systemd.enable = true;
        systemd.target = "graphical-session.target";
      };
      dux-calendar = {
        enable = true;
        systemd.enable = true;
        systemd.target = "graphical-session.target";
      };
    };

    # 让 DMS 启动的应用也拿到 fcitx5 环境变量。
    systemd.user.services.dms.environment = waylandImEnvironment;

    services.displayManager.dux-greeter = {
      enable = true;
      compositor.name = "niri";
      configHome = "/home/${username}";
    };

    services.xserver.displayManager.sessionCommands = ''
      ${pkgs.xorg.xrdb}/bin/xrdb -merge <<EOF
      Xft.dpi: 192
      EOF
    '';

    # Work around niri#2435 logout breaking user services
    systemd.user.services.niri = {
      serviceConfig.ExecStop = "${pkgs.systemd}/bin/systemctl --user stop graphical-session.target";
    };

    environment.systemPackages = with pkgs; [
      alacritty
      linux-wallpaperengine
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

    environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json" = {
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

              copy_if_missing_dir "${defaultNiriConfig}" "$HOME/.config/niri"
              copy_if_missing_dir "${defaultDmsConfig}" "$HOME/.config/dms"
            '';
          };
        })
    ];
  };
}
