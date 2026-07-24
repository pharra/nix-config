{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.home.pharra.gnome;
  gnome-macos-tahoe = pkgs.stdenv.mkDerivation {
    pname = "gnome-macos-tahoe";
    version = "0.6.4";
    src = pkgs.fetchFromGitHub {
      owner = "kayozxo";
      repo = "GNOME-macOS-Tahoe";
      tag = "v0.6.4";
      hash = "sha256-N+6eR0CQsQObd22tVduvIHYfvPA69AlXTJSYne1esi4=";
    };
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/themes
      cp -r gtk/Tahoe-Dark $out/share/themes/
      cp -r gtk/Tahoe-Light $out/share/themes/
      runHook postInstall
    '';
  };
  mactahoe-icon-theme = pkgs.stdenv.mkDerivation rec {
    pname = "mactahoe-icon-theme";
    version = "1.0.0";
    src = pkgs.fetchFromGitHub {
      owner = "vinceliuice";
      repo = "MacTahoe-icon-theme";
      rev = "main";
      sha256 = "sha256-CXZn4r1B+eB2Uv00vutFGQjOKJIia/I5RkPOBAAJKYA=";
    };

    nativeBuildInputs = [pkgs.gtk3];

    dontDropIconThemeCache = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/icons

      # Install all color variants
      # Available: default(blue)/purple/pink/red/orange/yellow/green/grey

      # Install default (blue) theme
      bash install.sh -d $out/share/icons -n MacTahoe -t default

      # Install other color variants if needed
      # bash install.sh -d $out/share/icons -n MacTahoe -t purple
      # bash install.sh -d $out/share/icons -n MacTahoe -t pink
      # bash install.sh -d $out/share/icons -n MacTahoe -t red
      # bash install.sh -d $out/share/icons -n MacTahoe -t orange
      # bash install.sh -d $out/share/icons -n MacTahoe -t yellow
      # bash install.sh -d $out/share/icons -n MacTahoe -t green
      # bash install.sh -d $out/share/icons -n MacTahoe -t grey

      # For 4K displays, use bold version:
      # bash install.sh -d $out/share/icons -n MacTahoe -t default -b

      find $out/share/icons -type l ! -exec test -e {} \; -delete

      # Update icon cache
      for theme in $out/share/icons/*; do
        if [ -f "$theme/index.theme" ]; then
          gtk-update-icon-cache -f -t $theme
        fi
      done

      runHook postInstall
    '';

    meta = with lib; {
      description = "MacOS Tahoe icon theme for Linux desktops";
      homepage = "https://github.com/vinceliuice/MacTahoe-icon-theme";
      license = licenses.gpl3Only;
      platforms = platforms.linux;
      maintainers = [];
    };
  };
in {
  options = {
    home.pharra.gnome = {
      enable = mkEnableOption "GNOME home configuration";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.sessionVariables = {
      "NIXOS_OZONE_WL" = "1"; # for any ozone-based browser & electron apps to run on wayland
      "MOZ_ENABLE_WAYLAND" = "1"; # for firefox to run on wayland
      "MOZ_WEBRENDER" = "1";
      "QT_QPA_PLATFORM" = "wayland";
    };

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        accent-color = "purple";
        color-scheme = "prefer-light";
        cursor-theme = "MacTahoe-light";
        document-font-name = "更纱黑体 UI SC 10";
        enable-animations = true;
        font-name = "更纱黑体 UI SC 10";
        gtk-theme = "Tahoe-Light";
        icon-theme = "MacTahoe-light";
        monospace-font-name = "等距更纱黑体 SC 10";
        scaling-factor = 2;
        text-scaling-factor = 1.0;
        toolbar-style = "text";
      };

      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = [
          "clipboard-indicator@tudmotu.com"
          "dash-to-dock@micxgx.gmail.com"
          "blur-my-shell@aunetx"
          # "user-theme@gnome-shell-extensions.gcampax.github.com"
        ];
      };
    };

    home.packages = with pkgs; [
      gnomeExtensions.blur-my-shell
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.dash-to-dock
      gnomeExtensions.user-themes
      gnomeExtensions.open-bar

      gnome-macos-tahoe
      mactahoe-icon-theme
    ];
  };
}
