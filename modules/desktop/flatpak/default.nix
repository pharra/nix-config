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

      # 必须放行 x11 socket：QQ 的启动脚本在沙箱里看不到 /tmp/.X11-unix 时会退回
      # `xvfb-run -a`，而 xvfb-run 靠 SIGUSR1 等 Xvfb 就绪；denial 启动子进程时只解
      # 锁了 SIGINT/SIGTERM，SIGUSR1 仍是 blocked，于是从 app launcher 启动会永久卡
      # 在 xvfb-run（shell 里掩码是空的，所以手动跑没问题）。放行 x11 后脚本走直接
      # exec 的分支；WAYLAND_DISPLAY 有值时 flags 依然是 --ozone-platform=wayland。
      "com.qq.QQ".Context.sockets = [
        "wayland"
        "x11"
      ];
      "com.tencent.WeChat" = {
        Context.sockets = [
          "wayland"
        ];
        Context.filesystems = [
          "xdg-download"
          "/fluent"
        ];
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
