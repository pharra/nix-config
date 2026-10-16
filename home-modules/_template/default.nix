# 新 Home Manager 模块骨架：复制到 home-modules/<你的名字>/，把 my-module 换成你的名字。
# 这个目录以 _ 开头，lib/importModules.nix 会跳过它。
#
# 约定：
#   1. 开关统一放 home.pharra.* 下（本仓库唯一的 home 命名空间，不要再定义 services.* 之类的越界选项）
#   2. 必须有 enable 开关，默认关闭；在 lib/variants.nix 的 homeSwitch 表里按需打开（build 变体）
#   3. 需要读系统侧开关时用 osConfig，例如 osConfig.services.pharra.desktop-shell.variant
#   4. 分层用 lib.mkDefault，不要用 mkForce
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.home.pharra.my-module;
in {
  options.home.pharra.my-module = {
    enable = mkEnableOption "一句话说明这个 home 模块做什么";
  };

  config = mkIf cfg.enable {
    # 这里写 home.* / programs.* / xdg.* 之类的配置
  };
}
