{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.hardware.mlx5;

  opensmCommon = import ../opensm.nix {inherit lib pkgs;};
in {
  options.hardware.mlx5 = {
    enable = mkEnableOption "MLX5 Configuration";

    interfaces = lib.mkOption {
      description = "要交给 mlx5 管理的网卡名";
      type = types.listOf types.str;
      default = [];
    };

    opensm = opensmCommon.option;
  };

  config = lib.mkIf cfg.enable {
    boot.kernelModules = [
      "mlx5_core"
      "mlx5_ib"
      "rdma_ucm"
      "xprtrdma"
      "svcrdma"
    ];

    boot.initrd.kernelModules = [
      "mlx5_core"
      "mlx5_ib"
      "rdma_ucm"
      "xprtrdma"
      "svcrdma"
    ];

    environment.systemPackages = with pkgs; [
      opensm
      rdma-core
      mstflint
    ];

    systemd.services.opensm = mkIf cfg.opensm (opensmCommon.service opensmCommon.launchScript);
  };
}
