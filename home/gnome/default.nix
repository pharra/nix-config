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
  };

  dconf.settings = {
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
      ];
    };

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-light";
      enable-hot-corners = true;
      clock-show-weekday = true;
      cursor-theme = "Adwaita";
      gtk-theme = "Adwaita";
    };

    "org/gnome/desktop/privacy" = {
      report-technical-problems = "false";
    };
    "org/gnome/desktop/calendar" = {
      show-weekdate = true;
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
    gnomeExtensions.battery-indicator-upower
    gnomeExtensions.just-perfection
    gnomeExtensions.caffeine
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.workspace-indicator-2
    gnomeExtensions.bluetooth-quick-connect
    gnomeExtensions.gsconnect # kdeconnect enabled in default.nix
    gnomeExtensions.pip-on-top
    gnomeExtensions.pop-shell
    gnomeExtensions.forge
    # gnomeExtensions.fullscreen-avoider
    gnomeExtensions.dash-to-dock
    gnomeExtensions.freon
    gnomeExtensions.kimpanel
  ];
}
