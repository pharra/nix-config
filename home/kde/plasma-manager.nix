{
  programs.plasma = {
    enable = true;
    shortcuts = {
      "org_kde_powerdevil"."Turn Off Screen" = "none";
    };
    configFile = {
      "kdeglobals"."KDE"."SingleClick" = false;
      "kwinrc"."Wayland"."InputMethod[$e]" = "/run/current-system/sw/share/applications/org.fcitx.Fcitx5.desktop";
      "kwinrc"."Wayland"."VirtualKeyboardEnabled" = true;
      "kwinrc"."Xwayland"."Scale" = 2;
      "kxkbrc"."Layout"."DisplayNames" = "";
      "kxkbrc"."Layout"."LayoutList" = "us";
      "kxkbrc"."Layout"."Use" = true;
      "kxkbrc"."Layout"."VariantList" = "";
      "plasma-localerc"."Formats"."LANG" = "zh_CN.UTF-8";
    };
  };
}
