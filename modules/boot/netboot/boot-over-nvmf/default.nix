# Guest module: Configure this NixOS to boot from NVMf or iSCSI
# This module is used on the guest machine that will boot via block storage
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nvmf-root;
  netboot = import ../netboot-root-common.nix {inherit lib pkgs;};
in {
  options = {
    services.nvmf-root = {
      enable = mkEnableOption "NVMf/iSCSI root boot (guest side)";

      interface = netboot.interfaceOption ["mlx5_0"];

      nvmf = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable NVMf boot.";
        };

        transport = mkOption {
          type = types.enum ["tcp" "rdma"];
          default = "rdma";
          description = "NVMf transport protocol (tcp or rdma).";
        };

        target = mkOption {
          type = types.str;
          default = "nqn.2016-06.io.spdk:fluent_nixos";
          description = "The NVMf target name.";
        };

        address = mkOption {
          type = types.str;
          default = "192.168.29.1";
          description = "The NVMf target address.";
        };

        port = mkOption {
          type = types.int;
          default = 4420;
          description = "The NVMf target port.";
        };
      };

      iscsi = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable iSCSI boot.";
        };

        initiatorName = mkOption {
          type = types.str;
          default = "iqn.2020-08.org.linux-iscsi.initiatorhost:fluent";
          description = "The iSCSI initiator name.";
        };

        discoveryAddress = mkOption {
          type = types.str;
          default = "192.168.29.1";
          description = "The iSCSI discovery portal address.";
        };

        targetName = mkOption {
          type = types.str;
          default = "iqn.2016-06.io.spdk:fluentnixosefi";
          description = "The iSCSI target name.";
        };
      };

      boot = netboot.bootOptions {kernelModulesDefault = [];};

      network = netboot.networkOption;
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.nvmf.enable || cfg.iscsi.enable;
        message = "services.nvmf-root: at least one of nvmf.enable or iscsi.enable must be true.";
      }
    ];

    boot = {
      kernelParams = cfg.boot.extraKernelParams;
    };

    # Configure NVMf module
    boot.nvmf = lib.mkIf cfg.nvmf.enable {
      enable = true;
      address = cfg.nvmf.address;
      port = cfg.nvmf.port;
      target = cfg.nvmf.target;
      type = cfg.nvmf.transport;
    };

    # Configure iSCSI module
    boot.iscsi-root = lib.mkIf cfg.iscsi.enable {
      name = cfg.iscsi.initiatorName;
      discoverPortal = cfg.iscsi.discoveryAddress;
      target = cfg.iscsi.targetName;
    };

    boot.initrd = {
      kernelModules = cfg.boot.kernelModules;
      systemd =
        (netboot.initrdSystemd {})
        // {
          services = {
            ensure-network-nvmf = netboot.ensureNetwork {peerAddress = cfg.nvmf.address;};
          };
          network = netboot.initrdNetwork cfg;
        };
      services.resolved.enable = true;
    };

    systemd.network.networks = netboot.stage2Network cfg;

    environment.systemPackages = with pkgs;
      []
      ++ lib.optionals cfg.nvmf.enable [nvme-cli]
      ++ lib.optionals cfg.iscsi.enable [openiscsi];
  };
}
