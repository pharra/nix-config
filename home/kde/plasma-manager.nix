{
  programs.plasma = {
    enable = true;
    shortcuts = {
      "org_kde_powerdevil"."Turn Off Screen" = [];
    };
    configFile = {
      "kdeglobals"."KDE"."SingleClick".value = false;
      "kwinrc"."Wayland"."InputMethod[$e]".value = "/run/current-system/sw/share/applications/org.fcitx.Fcitx5.desktop";
      "kwinrc"."Xwayland"."Scale".value = 2;
      "kxkbrc"."Layout"."DisplayNames".value = "";
      "kxkbrc"."Layout"."LayoutList".value = "us";
      "kxkbrc"."Layout"."Use".value = true;
      "kxkbrc"."Layout"."VariantList".value = "";
      "plasma-localerc"."Formats"."LANG".value = "en_US.UTF-8";
    };
  };
}
