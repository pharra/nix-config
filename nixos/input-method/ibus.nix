{
  pkgs,
  lib,
  config,
  ...
} @ args: {
  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = with pkgs.ibus-engines; [
      (rime.override {rimeDataPkgs = [];})
    ];
  };

  # Extra variables not covered by NixOS fcitx module
  environment.variables = {
    GTK_IM_MODULE = "ibus";
    QT_IM_MODULE = "ibus";
    XMODIFIERS = "@im=ibus";
  };
}
