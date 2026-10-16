# 自动导入本目录下所有服务模块（每个 <name>/default.nix 一个服务）。
# 之前这里是手工维护的 imports 列表，新增服务容易忘记登记。
{...}: {
  imports = builtins.attrValues (import ../lib/importModules.nix {dir = ./.;});
}
