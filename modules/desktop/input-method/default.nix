{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib; let
  cfg = config.services.pharra.input-method;

  wanxiangModel = pkgs.fetchurl {
    url = "https://github.com/jetcookies/RIME-LMDG-tracker/releases/download/0-unstable-2026-08-18/wanxiang-lts-zh-hans.gram";
    sha256 = "sha256-PeIaH/WHq04YjC3cVpVdnSXxBPTQzleU8FptkQOuN8s=";
  };
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
          rimeDataPkgs = [
            rime-wanxiang
          ];
        })
        qt6Packages.fcitx5-chinese-addons
        qt6Packages.fcitx5-with-addons
        fcitx5-fluent
        fcitx5-mellow-themes
      ];
    };

    environment.variables = {
      XMODIFIERS = "@im=fcitx";
    };

    hjem.extraModules = [
      ({config, ...}:
        mkIf (config.user == username) {
          xdg.config.files = {
            "fcitx5/profile".source = ./profile;
            "fcitx5/conf/classicui.conf".source = ./classicui.conf;
          };

          xdg.data.files = {
            "fcitx5/rime/wanxiang-lts-zh-hans.gram".source = "${wanxiangModel}";
            "fcitx5/rime/default.custom.yaml".text = ''
              patch:
                __include: wanxiang_suggested_default:/
            '';
          };
        })
    ];
  };
}
