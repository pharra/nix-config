{
  pkgs,
  rime-config,
  config,
  lib,
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
  home.file.".config/ibus/rime" = {
    source = merged-rime-config;
    # 强制替换以确保 rime 配置始终是最新的
    force = true;
    recursive = true;
  };
}
