{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.pharra.kde;
  # wallpaper-engine-kde-plugin = with pkgs;
  #   stdenv.mkDerivation rec {
  #     pname = "wallpaperEngineKde";
  #     version = "c0c08ad73a1eb773acbcd7854d2807115bd9d5a6";
  #     src = fetchFromGitHub {
  #       owner = "rainypixel";
  #       repo = "wallpaper-engine-kde-plugin";
  #       rev = "c0c08ad73a1eb773acbcd7854d2807115bd9d5a6";
  #       hash = "sha256-516wvxhMPxMulzEWnf4LvPIRqfVPOM9OLnFZQ1gVqGU=";
  #       fetchSubmodules = true;
  #     };
  #     nativeBuildInputs = [
  #       cmake
  #       kdePackages.extra-cmake-modules
  #       pkg-config
  #       gst_all_1.gst-libav
  #       shaderc
  #       ninja
  #     ];
  #     buildInputs =
  #       [
  #         mpv
  #         libass
  #         lz4
  #         vulkan-headers
  #         vulkan-tools
  #         vulkan-loader
  #         eigen
  #       ]
  #       ++ (with kdePackages; [
  #         qtbase
  #         kpackage
  #         kdeclarative
  #         libplasma
  #         qtwebsockets
  #         qtwebengine
  #         qtwebchannel
  #         qtmultimedia
  #         qtdeclarative
  #       ])
  #       ++ [
  #         # Add .dev output for Qt private headers
  #         qt6Packages.qtbase.dev
  #       ];
  #     cmakeFlags = [
  #       "-DUSE_PLASMAPKG=OFF"
  #     ];
  #     # Add Qt private headers path
  #     NIX_CFLAGS_COMPILE = [
  #       "-Wno-error"
  #       "-Wno-sign-conversion"
  #       "-Wno-deprecated-declarations"
  #       "-I${pkgs.qt6Packages.qtbase.dev}/include/QtGui/${pkgs.qt6Packages.qtbase.version}/QtGui"
  #     ];
  #     dontWrapQtApps = true;
  #     postPatch = ''
  #     '';
  #     postInstall = ''
  #     '';
  #     #Optional informations
  #     meta = with lib; {
  #       description = "Wallpaper Engine KDE plasma plugin";
  #       homepage = "https://github.com/Jelgnum/wallpaper-engine-kde-plugin";
  #       license = licenses.gpl2Plus;
  #       platforms = platforms.linux;
  #     };
  #   };
in {
  options = {
    services.pharra.kde = {
      enable = mkEnableOption "KDE Plasma desktop environment";
    };
  };

  config = mkIf cfg.enable {
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

      # wallpaper-engine-kde-plugin

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
      wayland-utils # Wayland utilities
      wl-clipboard # Command-line copy/paste utilities for Wayland
    ];

    # 不用 kwallet：Secret Service 统一走 gnome-keyring（见 modules/core/desktop）。
    # 排除它是为了避免 Chromium 在 KDE 下优先选 kwallet，导致切换桌面变体时 cookie 解密密钥换了地方。
    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      kwallet # provides helper service
      kwallet-pam # provides helper service
      kwalletmanager # provides KCMs and stuff
    ];

    # kwallet 的 PAM 自动解锁也关掉（否则登录时会把 kwalletd 拉起来）
    security.pam.services.login.kwallet.enable = lib.mkForce false;
    security.pam.services.kde.kwallet.enable = lib.mkForce false;

    # plasmalogin 的 PAM 服务不走 login，单独挂上 gnome-keyring 自动解锁
    security.pam.services.plasmalogin.enableGnomeKeyring = true;
  };
}
