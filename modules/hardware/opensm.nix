# mlx5 用的 OpenSM（InfiniBand 子网管理器）片段。
# 它原来在 mlx4 / mlx5 两个模块里各写了一份（逐字相同），后来 mlx4 模块被删除，
# 这里保留下来给 mlx5 用，避免以后 mlx5 自己被复制一份。
#
# 注意：这是普通 .nix 文件（不是含 default.nix 的目录），所以不会被 importModules 当成模块自动导入。
{
  lib,
  pkgs,
}: let
  inherit (lib) mkOption types;
in rec {
  option = mkOption {
    type = types.bool;
    default = false;
    description = "启动 OpenSM 子网管理器";
  };

  launchScript = pkgs.writeShellScriptBin "opensm.launch" ''
    (while true; do ${pkgs.opensm}/bin/opensm; sleep 30; done) &
    exit 0
  '';

  service = launchScript: {
    enable = true;
    wantedBy = ["network.target"];
    #after = ["rdma.service"];
    #requires = ["rdma.service"];
    description = "Starts the OpenSM InfiniBand fabric Subnet Manager";
    documentation = ["man:opensm"];
    before = ["network.target" "remote-fs-pre.target"];
    unitConfig = {
      DefaultDependencies = "no";
    };
    serviceConfig = {
      Type = "forking";
      ExecStart = "${launchScript}/bin/opensm.launch";
    };
  };
}
