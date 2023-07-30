{
  pkgs,
  lib,
  config,
  utils,
  inputs,
  ...
} @ args: {
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
      fcitx5-rime
      fcitx5-chinese-addons
      fcitx5-with-addons
    ];
  };

  # Extra variables not covered by NixOS fcitx module
  environment.variables = {
    INPUT_METHOD = "fcitx";
    SDL_IM_MODULE = "fcitx";
    GLFW_IM_MODULE = "ibus";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    IMSETTINGS_MODULE = "fcitx";
  };
}
