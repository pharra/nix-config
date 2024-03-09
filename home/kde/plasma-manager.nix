{
  programs.plasma = {
    enable = true;
    shortcuts = {
      "org_kde_powerdevil"."Turn Off Screen" = [];
    };
    configFile = {
      "kdeglobals"."KDE"."SingleClick" = false;
      "kwinrc"."Wayland"."InputMethod[$e]" = "/run/current-system/sw/share/applications/org.fcitx.Fcitx5.desktop";
      "kwinrc"."Xwayland"."Scale" = 1.75;
      "kxkbrc"."Layout"."DisplayNames" = "";
      "kxkbrc"."Layout"."LayoutList" = "us";
      "kxkbrc"."Layout"."Use" = true;
      "kxkbrc"."Layout"."VariantList" = "";
      "plasma-localerc"."Formats"."LANG" = "en_US.UTF-8";
    };
  };
}
