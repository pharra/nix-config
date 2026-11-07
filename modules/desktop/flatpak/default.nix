{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.pharra.flatpak;
in {
  options = {
    services.pharra.flatpak = {
      enable = mkEnableOption "flatpak support";
    };
  };

  config = mkIf cfg.enable {
    ###################################################################################
    #
    #  Enable flatpak
    #
    ###################################################################################

    # https://flatpak.org/setup/NixOS
    services.flatpak.enable = true;

    # already have a network wait online service
    # systemd.services."flatpak-managed-install" = {
    #   serviceConfig = {
    #     ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
    #   };
    # };

    services.flatpak.remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo";
      }
    ];

    services.flatpak.update.auto = {
      enable = true;
      onCalendar = "daily"; # Default value
    };

    services.flatpak.overrides = {
      global = {
        Context.filesystems = [
          "xdg-config/fontconfig:ro" # fix fontconfig not working in flatpak apps
        ];
      };
      # Edge 是 Chromium 系：cookie/密码的加密密钥存在 Secret Service 里。KDE 下 Chromium 会优先
      # 选 kwallet，一切换桌面变体密钥就"换了地方" → 所有登录失效。这里把它的桌面检测固定成
      # GNOME（→ 用 gnome-libsecret），并放行 session bus 上的 org.freedesktop.secrets。
      "com.microsoft.Edge" = {
        Environment.XDG_CURRENT_DESKTOP = "GNOME";
        "Session Bus Policy"."org.freedesktop.secrets" = "talk";
      };

      "com.qq.QQ".Context.sockets = [
        "!x11"
        "wayland"
        "!fallback-x11"
      ];
      # 微信是 Qt6 原生 Wayland 程序；Flatpak 沙箱里没有宿主 fcitx5-qt 模块，
      # 用 Qt 私有的 text-input-v3 后端直接走 Wayland 输入法协议，
      # 这样仍然保持原生 Wayland，不需要退回 XWayland。
      "com.tencent.WeChat" = {
        Context.sockets = [
          "wayland"
        ];
        Context.filesystems = [
          "xdg-download"
          "/fluent"
        ];
        Environment = {
          QT_QPA_PLATFORM = "wayland";
          QT_IM_MODULE = "text-input-unstable-v3";
        };
        "Session Bus Policy" = {
          "org.fcitx.Fcitx5" = "talk";
          "org.fcitx.Fcitx-0" = "talk";
        };
      };
    };

    services.flatpak.packages = [
      {
        appId = "io.github.qier222.YesPlayMusic";
        origin = "flathub";
      }
      {
        appId = "com.microsoft.Edge";
        origin = "flathub";
      }
      {
        appId = "org.localsend.localsend_app";
        origin = "flathub";
      }
      {
        appId = "com.qq.QQ";
        origin = "flathub";
      }
      {
        appId = "com.tencent.WeChat";
        origin = "flathub";
      }
      {
        appId = "org.qbittorrent.qBittorrent";
        origin = "flathub";
      }
      {
        appId = "org.telegram.desktop";
        origin = "flathub";
      }
      {
        appId = "org.videolan.VLC";
        origin = "flathub";
      }
      {
        appId = "net.lutris.Lutris";
        origin = "flathub";
      }
    ];
  };
}
