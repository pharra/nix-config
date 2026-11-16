{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib; let
  cfg = config.services.pharra.kde;
in {
  options = {
    services.pharra.kde = {
      enable = mkEnableOption "KDE Plasma desktop environment";
    };
  };

  config = mkIf cfg.enable {
    # KWallet 6 的 KWallet API 服务只是 Secret Service 的代理；
    # 关闭 ksecretd 并启用迁移后，KWallet API 会落到 gnome-keyring。
    # 这样不需要伪造 XDG_CURRENT_DESKTOP 或 patch startplasma。
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;

    programs = {
      dconf.enable = true;
      kdeconnect.enable = true;
    };

    services = {
      displayManager.plasma-login-manager.enable = true; # Display Manager
      desktopManager.plasma6.enable = true; # Window Manager
      # displayManager.autoLogin = {
      #   enable = true;
      #   user = "${username}";
      # };
    };

    xdg.portal = {
      extraPortals = [
        # fix some flatpak apps not apply font config in KDE Plasma
        pkgs.kdePackages.xdg-desktop-portal-kde
      ];
    };

    environment.systemPackages = with pkgs; [
      kdePackages.kirigami

      kdePackages.qtwebsockets
      kdePackages.qtwebengine
      kdePackages.qtwebchannel
      kdePackages.qtmultimedia
      kdePackages.qtdeclarative

      kdePackages.discover # Optional: Install if you use Flatpak or fwupd firmware update sevice
      kdePackages.kcalc # Calculator
      kdePackages.kcharselect # Tool to select and copy special characters from all installed fonts
      kdePackages.kcolorchooser # A small utility to select a color
      kdePackages.kolourpaint # Easy-to-use paint program
      kdePackages.ksystemlog # KDE SystemLog Application
      kdiff3 # Compares and merges 2 or 3 files or directories
      kdePackages.isoimagewriter # Optional: Program to write hybrid ISO files onto USB disks
      kdePackages.partitionmanager # Optional Manage the disk devices, partitions and file systems on your computer
      hardinfo2 # System information and benchmarks for Linux systems
      haruna # Open source video player built with Qt/QML and libmpv
      waywallen-display-kde
      wayland-utils # Wayland utilities
      wl-clipboard # Command-line copy/paste utilities for Wayland
    ];

    # 不再把 KWallet 当作 Secret Service 的兼容层；只保留 gnome-keyring。
    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      kwallet-pam # 不需要 kwallet 的 PAM 解锁，gnome-keyring 已由 PAM 解锁
      kwalletmanager # 不需要 KWallet GUI
    ];

    xdg.portal.config = {
      # 值必须是 portal 实现名（.portal 文件名），不是桌面名。
      "kde" = {
        "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
      };
      "gnome" = {
        "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
      };
    };

    # kwallet 的 PAM 自动解锁也关掉（否则登录时会把 kwalletd 拉起来）
    security.pam.services.login.kwallet.enable = lib.mkForce false;
    security.pam.services.plasmalogin.kwallet.enable = lib.mkForce false;

    # plasmalogin 的 PAM 服务不走 login，单独挂上 gnome-keyring 自动解锁
    security.pam.services.plasmalogin.enableGnomeKeyring = true;

    # KWallet API 保持可用（KWallet API -> Secret Service 代理），
    # 但不再启动 ksecretd；把后端迁移到已有的 Secret Service（gnome-keyring）。
    systemd.user.services.ensure-kwalletrc = {
      wantedBy = ["default.target"];
      serviceConfig.Type = "oneshot";
      script = ''
        rc="$HOME/.config/kwalletrc"
        if [ ! -e "$rc" ]; then
          ${pkgs.coreutils}/bin/install -Dm600 ${pkgs.writeText "kwalletrc" ''
            [KSecretD]
            Enabled=false

            [Migration]
            MigrateTo3rdParty=true
          ''} "$rc"
        fi
      '';
      startLimitBurst = 0;
      startLimitIntervalSec = 0;
    };

    environment.sessionVariables = {
      "NIXOS_OZONE_WL" = "1";
      "MOZ_ENABLE_WAYLAND" = "1";
      "MOZ_WEBRENDER" = "1";
      "QT_QPA_PLATFORM" = "wayland";
    };
  };
}
