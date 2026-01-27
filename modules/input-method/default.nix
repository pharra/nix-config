{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.pharra.input-method;
in {
  options = {
    services.pharra.input-method = {
      enable = mkEnableOption "input method (fcitx5)";
    };
  };

  config = mkIf cfg.enable {
    i18n.inputMethod = {
      type = "fcitx5";
      enable = true;
      fcitx5.waylandFrontend = true;
      fcitx5.addons = with pkgs; [
        fcitx5-mozc
        fcitx5-gtk
        (fcitx5-rime.override {
          rimeDataPkgs = [];
        })
        qt6Packages.fcitx5-chinese-addons
        qt6Packages.fcitx5-with-addons
        fcitx5-fluent
        fcitx5-mellow-themes
      ];
    };

    # Extra variables not covered by NixOS fcitx module
    environment.variables = {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
    };
  };
}
