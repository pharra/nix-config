{
  lib,
  pkgs,
  username,
  config,
  ...
}: {
  ###################################################################################
  #
  #  Enable flatpak
  #
  ###################################################################################

  # https://flatpak.org/setup/NixOS
  services.flatpak.enable = true;

  systemd.services."flatpak-managed-install" = {
    serviceConfig = {
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
    };
  };

  services.flatpak.remotes = [
    {
      name = "flathub";
      location = "https://mirror.sjtu.edu.cn/flathub/flathub.flatpakrepo";
    }
    {
      name = "flathub-origin";
      location = "https://flathub.org/repo/flathub.flatpakrepo";
    }
  ];

  services.flatpak.packages = [
    {
      appId = "io.github.hypengw.Qcm";
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
  ];
}
