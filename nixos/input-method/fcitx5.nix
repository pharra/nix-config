{
  pkgs,
  lib,
  config,
  utils,
  ...
} @ args: {
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
    # INPUT_METHOD = "fcitx";
    # SDL_IM_MODULE = "fcitx";
    # GLFW_IM_MODULE = "ibus";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    # IMSETTINGS_MODULE = "fcitx";
  };
}
