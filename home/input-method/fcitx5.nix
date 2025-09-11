{
  pkgs,
  config,
  lib,
  rime-config,
  ...
}: let
  # 合并所有 rime 配置源 (后面的会覆盖前面的同名文件)
  merged-rime-config = pkgs.symlinkJoin {
    name = "merged-rime-config";
    paths = [
      rime-config # 基础配置(https://www.mintimate.cc/zh/guide/)
      # rime-lmdg-lts # LMDG 词库
      # inputs.my-rime-config # 个人配置 (优先级最高，会覆盖前面的同名文件)
    ];
  };
in {
  home.file.".config/fcitx5/profile".source = ./profile;
  home.file.".config/fcitx5/profile-bak".source = ./profile; # used for backup

  xdg.dataFile."fcitx5/rime" = {
    source = merged-rime-config;
    # 强制替换以确保 rime 配置始终是最新的
    force = true;
    recursive = true;
  };

  programs.plasma = {
    enable = true;
    configFile = {
      "kwinrc"."Wayland"."InputMethod[$e]" = "/run/current-system/sw/share/applications/org.fcitx.Fcitx5.desktop";
    };
  };

  # every time fcitx5 switch input method, it will modify ~/.config/fcitx5/profile file,
  # which will override my config managed by home-manager
  # so we need to remove it before everytime we rebuild the config
  home.activation.removeExistingFcitx5Profile = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    rm -f "${config.xdg.configHome}/fcitx5/profile"
  '';
}
