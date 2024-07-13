{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.hardware.mlx5;

  opensm-launch = pkgs.writeShellScriptBin "opensm.launch" ''
    (while true; do ${pkgs.opensm}/bin/opensm; sleep 30; done) &
    exit 0
  '';
in {
  options.hardware.mlx5 = {
    enable = mkEnableOption "MLX5 Configuration";

    enableSRIOV = mkOption {
      type = types.bool;
      default = true;
    };

    interfaces = lib.mkOption {
      type = types.listOf types.str;
      default = [];
    };

    opensm = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelModules = [
      "mlx5_core"
      "mlx5_ib"
    ];

    boot.initrd.kernelModules = [
      "mlx5_core"
      "mlx5_ib"
    ];

    environment.systemPackages = with pkgs; [
      opensm
      rdma-core
      mstflint
    ];

    systemd.services.mlx5-sriov = lib.mkIf cfg.enableSRIOV {
      enable = true;
      script = "set -e\n" + concatMapStringsSep "\n" (interface: "echo 8 | tee /sys/class/net/${interface}/device/sriov_numvfs") cfg.interfaces;
      requiredBy = ["libvirtd.service"];
      before = ["libvirtd.service"];
      serviceConfig = {
        Type = "oneshot";
      };
    };

    systemd.services.opensm = mkIf cfg.opensm {
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
        ExecStart = ''${opensm-launch}/bin/opensm.launch'';
      };
    };
  };
}
