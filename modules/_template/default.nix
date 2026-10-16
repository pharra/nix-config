# 新模块骨架：把这个目录复制到 modules/<域>/<你的名字>/，并把下面的 my-module 换成你的名字。
# 这个目录以 _ 开头，lib/importModules.nix 会跳过它，所以放在 modules/ 下不会被当成模块加载。
#
# 约定（详见 README 的「模块的命名与组织规则」）：
#   1. 域只有 4 个：services.pharra.*（自有服务，默认放这里）/ hardware.* / boot.* / virtualisation.*
#   2. 目录名 = 选项路径的最后一段，统一 kebab-case（例如 modules/network/dhcp-server -> services.pharra.dhcp-server）
#   3. 必须有 enable 开关（mkEnableOption），默认关闭
#   4. 不要硬编码宿主信息：用户名用 specialArgs 里的 username，网段/掩码/路径做成选项
#   5. 分层用 lib.mkDefault，不要用 mkForce
#   6. 脚本/模板正文超过 ~30 行就放同目录独立 .nix 文件（保持字符串字面量，Nix 插值才有效）：
#        # ./script.nix
#        {pkgs}: ''
#          ${pkgs.coreutils}/bin/echo hi
#        ''
#      这里用 (import ./script.nix {inherit pkgs;}) 引用；注意不要抽成 .sh 再用 readFile，
#      那样 ${...} 插值会变成字面量。
#
# 模块函数可以按需从参数里取：config / lib / pkgs / username / mysecrets / inputs / NixVirt / agenix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.pharra.my-module;
in {
  options.services.pharra.my-module = {
    enable = mkEnableOption "一句话说明这个模块做什么";
  };

  config = mkIf cfg.enable {
    # 实际配置写在这里
  };
}
