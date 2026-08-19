{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.home.pharra.input-method;

  wanxiangModel = pkgs.fetchurl {
    url = "https://github.com/jetcookies/RIME-LMDG-tracker/releases/download/0-unstable-2026-08-18/wanxiang-lts-zh-hans.gram";
    sha256 = "sha256-PeIaH/WHq04YjC3cVpVdnSXxBPTQzleU8FptkQOuN8s=";
  };
in {
  options = {
    home.pharra.input-method = {
      enable = mkEnableOption "input method (fcitx5) configuration";
    };
  };

  config = mkIf cfg.enable {
    home.file.".config/fcitx5/profile".source = ./profile;
    home.file.".config/fcitx5/conf/classicui.conf".source = ./classicui.conf;

    xdg.dataFile."fcitx5/rime/wanxiang-lts-zh-hans.gram".source = wanxiangModel;

    xdg.dataFile."fcitx5/rime/default.custom.yaml" = {
      text = ''
        patch:
          __include: wanxiang_suggested_default:/
      '';
    };

    # every time fcitx5 switch input method, it will modify ~/.config/fcitx5/profile file,
    # which will override my config managed by home-manager
    # so we need to remove it before everytime we rebuild the config
    home.activation.removeExistingFcitx5Profile = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
      rm -f "${config.xdg.configHome}/fcitx5/profile"
      rm -f "${config.xdg.configHome}/fcitx5/conf/classicui.conf"
    '';
  };
}
