# 休眠模块：hosts/homelab/hardware-configuration.nix 配置了参数，但 hardware.mlx4.enable 从没开过（配了不生效）。
{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.hardware.mlx4;

  opensmCommon = import ../opensm.nix {inherit lib pkgs;};
in {
  options.hardware.mlx4 = {
    enable = mkEnableOption "MLX4 Configuration";
    infiniband = mkOption {
      type = types.bool;
      default = false;
    };

    enableSRIOV = mkOption {
      type = types.bool;
      default = false;
    };

    applyPatch = mkOption {
      type = types.bool;
      default = false;
    };

    opensm = opensmCommon.option;

    portTypeArray = mkOption {
      type = types.str;
      default = "2,2";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.extraModprobeConfig = lib.mkIf cfg.enableSRIOV "options mlx4_core port_type_array=${cfg.portTypeArray} num_vfs=4,4,0 msi_x=1 enable_4k_uar=1 enable_qos=1 log_num_mac=7 log_num_mgm_entry_size=-1 log_mtts_per_seg=4";

    boot.kernelModules = lib.mkBefore [
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

    boot.initrd.kernelModules = lib.mkBefore [
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

    boot.kernelPatches = lib.mkIf cfg.applyPatch [
      {
        name = "mlx4-kernelPatches";
        patch = ./mlx4.patch;
      }
    ];

    environment.systemPackages = with pkgs; [
      opensm
      rdma-core
    ];

    systemd.services.rdma = {
      enable = false;
      wantedBy = ["network.target"];
      description = "Load RDMA modules";
      documentation = ["man:opensm"];
      conflicts = ["shutdown.target"];
      before = ["shutdown.target" "network-pre.target"];
      unitConfig = {
        ConditionCapability = ["CAP_SYS_MODULE"];
      };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        ExecStart = [
          "${pkgs.systemd}/lib/systemd/systemd-modules-load ${pkgs.rdma-core}/etc/rdma/modules/infiniband.conf"
          "${pkgs.systemd}/lib/systemd/systemd-modules-load ${pkgs.rdma-core}/etc/rdma/modules/rdma.conf"
        ];
        TimeoutSec = "90s";
      };
    };
    systemd.services.opensm = mkIf cfg.opensm (opensmCommon.service opensmCommon.launchScript);
  };
}
