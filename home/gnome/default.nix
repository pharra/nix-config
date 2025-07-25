{pkgs, ...}: {
  imports = [
    ./gnome-apps.nix
  ];

  # allow fontconfig to discover fonts and configurations installed through home.packages
  fonts.fontconfig.enable = true;

  systemd.user.sessionVariables = {
    "NIXOS_OZONE_WL" = "1"; # for any ozone-based browser & electron apps to run on wayland
    "MOZ_ENABLE_WAYLAND" = "1"; # for firefox to run on wayland
    "MOZ_WEBRENDER" = "1";
    "QT_QPA_PLATFORM" = "wayland";
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      clock-show-weekday = true;
      color-scheme = "prefer-light";
      cursor-size = 24;
      cursor-theme = "Adwaita";
      enable-animations = true;
      enable-hot-corners = true;
      font-name = "Noto Sans,  10";
      gtk-theme = "Adwaita";
      icon-theme = "breeze";
      scaling-factor = 2;
      text-scaling-factor = 1.0;
      toolbar-style = "text";
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "icon:minimize,maximize,close";
    };

    "org/gnome/desktop/remote-desktop/rdp" = {
      enable = true;
      screen-share-mode = "extend";
      view-only = false;
    };

    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        # "trayIconsReloaded@selfmade.pl"
        # "blur-my-shell@aunetx"
        # "drive-menu@gnome-shell-extensions.gcampax.github.com"
        # "dash-to-panel@jderose9.github.com"
        # "just-perfection-desktop@just-perfection"
        "caffeine@patapon.info"
        "clipboard-indicator@tudmotu.com"
        # "horizontal-workspace-indicator@tty2.io"
        "bluetooth-quick-connect@bjarosze.gmail.com"
        # "battery-indicator@jgotti.org"
        "gsconnect@andyholmes.github.io"
        # "pip-on-top@rafostar.github.com"
        # "forge@jmmaranan.com"
        "dash-to-dock@micxgx.gmail.com" # Dash to panel alternative
        # "fullscreen-avoider@noobsai.github.com"     # Incompatible with dash-to-panel
        "kimpanel@kde.org"
        "appindicatorsupport@rgcjonas.gmail.com"
      ];
    };

    "org/gnome/desktop/privacy" = {
      report-technical-problems = "false";
    };
    "org/gnome/desktop/calendar" = {
      show-weekdate = true;
    };
    "org/gnome/shell/extensions/caffeine" = {
      countdown-timer = 0;
      indicator-position-max = 1;
      toggle-state = true;
      user-enabled = true;
    };

    "org/gnome/shell/extensions/bluetooth-quick-connect" = {
      show-battery-icon-on = true;
      show-battery-value-on = true;
    };
  };

  home.packages = with pkgs; [
    gnomeExtensions.tray-icons-reloaded
    gnomeExtensions.blur-my-shell
    gnomeExtensions.removable-drive-menu
    gnomeExtensions.dash-to-panel
    # gnomeExtensions.battery-indicator-upower
    gnomeExtensions.just-perfection
    gnomeExtensions.caffeine
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.bluetooth-quick-connect
    gnomeExtensions.gsconnect # kdeconnect enabled in default.nix
    gnomeExtensions.pip-on-top
    gnomeExtensions.pop-shell
    gnomeExtensions.forge
    # gnomeExtensions.fullscreen-avoider
    gnomeExtensions.dash-to-dock
    gnomeExtensions.freon
    gnomeExtensions.kimpanel
    gnomeExtensions.appindicator
  ];
}
