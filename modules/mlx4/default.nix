{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.hardware.mlx4;
in {
  options.hardware.mlx4 = {
    enable = mkEnableOption "MLX4 Configuration";
  };

  config = lib.mkIf cfg.enable {
    boot.extraModprobeConfig = "options mlx4_core port_type_array=2,2 num_vfs=8 msi_x=1 enable_4k_uar=1 enable_qos=1 log_num_mac=7 log_num_mgm_entry_size=-1 log_mtts_per_seg=4";

    boot.kernelModules = [
      "mlx4_core"
      "mlx4_en"
      "mlx4_ib"
      "ib_ipoib"
      "ib_umad"
      "ib_srpt"
      "ib_iser"
      "ib_uverbs"
      "rdma_ucm"
      "xprtrdma"
      "svcrdma"
    ];

    boot.initrd.kernelModules = [
      "mlx4_core"
      "mlx4_en"
      "mlx4_ib"
      "ib_ipoib"
      "ib_umad"
      "ib_srpt"
      "ib_iser"
      "ib_uverbs"
      "rdma_ucm"
      "xprtrdma"
      "svcrdma"
    ];

    boot.kernelPatches = [
      {
        name = "mlx4-kernelPatches";
        patch = ./mlx4.patch;
      }
    ];
  };
}
