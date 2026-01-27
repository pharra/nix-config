{
  config,
  lib,
  pkgs,
  username,
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

    services.flatpak.overrides = {
      global = {
        Context.filesystems = [
          "xdg-config/fontconfig:ro" # fix fontconfig not working in flatpak apps
        ];
      };
      "com.qq.QQ".Context.sockets = [
        "x11"
        "wayland"
        "!fallback-x11"
      ]; # No Wayland support
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
