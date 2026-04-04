{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib; let
  cfg = config.services.pharra.kde;
  wallpaper-engine-kde-plugin = with pkgs;
    stdenv.mkDerivation rec {
      pname = "wallpaperEngineKde";
      version = "5f7588fe037c83288204b50242f13f36ebd07119";
      src = fetchFromGitHub {
        owner = "rainypixel";
        repo = "wallpaper-engine-kde-plugin";
        rev = "5f7588fe037c83288204b50242f13f36ebd07119";
        hash = "sha256-PYaVWSD35HenHuzkm+sn4gbx4/wpneOrTZbFQ//zDRA=";
        fetchSubmodules = true;
      };

      nativeBuildInputs = [
        cmake
        kdePackages.extra-cmake-modules
        pkg-config
        gst_all_1.gst-libav
        shaderc
        ninja
      ];

      buildInputs =
        [
          mpv
          libass
          lz4
          vulkan-headers
          vulkan-tools
          vulkan-loader
          eigen
        ]
        ++ (with kdePackages; [
          qtbase
          kpackage
          kdeclarative
          libplasma
          qtwebsockets
          qtwebengine
          qtwebchannel
          qtmultimedia
          qtdeclarative
        ])
        ++ [
          # Add .dev output for Qt private headers
          qt6Packages.qtbase.dev
        ];

      cmakeFlags = [
        "-DUSE_PLASMAPKG=OFF"
      ];

      # Add Qt private headers path
      NIX_CFLAGS_COMPILE = [
        "-Wno-error"
        "-Wno-sign-conversion"
        "-Wno-deprecated-declarations"
        "-I${pkgs.qt6Packages.qtbase.dev}/include/QtGui/${pkgs.qt6Packages.qtbase.version}/QtGui"
      ];

      dontWrapQtApps = true;

      postPatch = ''
      '';

      postInstall = ''
      '';

      #Optional informations
      meta = with lib; {
        description = "Wallpaper Engine KDE plasma plugin";
        homepage = "https://github.com/Jelgnum/wallpaper-engine-kde-plugin";
        license = licenses.gpl2Plus;
        platforms = platforms.linux;
      };
    };
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

    environment.systemPackages = with pkgs; [
      kdePackages.kirigami

      wallpaper-engine-kde-plugin

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
      kdePackages.sddm-kcm # Configuration module for SDDM
      kdiff3 # Compares and merges 2 or 3 files or directories
      kdePackages.isoimagewriter # Optional: Program to write hybrid ISO files onto USB disks
      kdePackages.partitionmanager # Optional Manage the disk devices, partitions and file systems on your computer
      hardinfo2 # System information and benchmarks for Linux systems
      haruna # Open source video player built with Qt/QML and libmpv
      wayland-utils # Wayland utilities
      wl-clipboard # Command-line copy/paste utilities for Wayland
    ];

    # 尝试排除（效果有限，因为部分是必需依赖）
    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      kwallet # provides helper service
      kwallet-pam # provides helper service
      kwalletmanager # provides KCMs and stuff
    ];
  };
}
