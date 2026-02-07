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
in {
  options = {
    services.nvmf-root = {
      enable = mkEnableOption "NVMf/iSCSI root boot (guest side)";

      interface = mkOption {
        type = types.listOf types.str;
        default = ["mlx5_0"];
        description = "Network interfaces to bring up in initrd (first entry is used as primary).";
      };

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

      boot = {
        kernelModules = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Additional initrd kernel modules needed for block storage boot.";
        };

        extraKernelParams = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Additional kernel parameters.";
        };
      };

      network = {
        dhcp = mkOption {
          type = types.str;
          default = "ipv4";
          description = "DHCP configuration (ipv4, ipv6, yes, no).";
        };

        pingHost = mkOption {
          type = types.str;
          default = "1.1.1.1";
          description = "Host to ping to ensure network connectivity.";
        };
      };
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
    boot.iscsi-initiatord = lib.mkIf cfg.iscsi.enable {
      name = cfg.iscsi.initiatorName;
      discoverPortal = cfg.iscsi.discoveryAddress;
      target = cfg.iscsi.targetName;
    };

    boot.initrd = {
      kernelModules = cfg.boot.kernelModules;
      systemd = {
        enable = true;
        emergencyAccess = true;
        initrdBin = [pkgs.iproute2 pkgs.pciutils pkgs.dnsutils pkgs.util-linux pkgs.coreutils pkgs.iputils];

        services = {
          ensure-network = {
            enable = true;
            before = ["network-online.target"];
            wantedBy = ["network-online.target"];
            after = ["nss-lookup.target"];
            unitConfig.DefaultDependencies = "no";
            serviceConfig = {
              Type = "oneshot";
              TimeoutStartSec = 60;
              ExecStart = "${pkgs.bashInteractive}/bin/sh -c 'until ${pkgs.iputils}/bin/ping -c 1 ${cfg.network.pingHost}; do ${pkgs.coreutils}/bin/sleep 1; done'";
            };
          };
        };

        network = {
          enable = true;
          wait-online = {
            anyInterface = lib.mkForce false;
            timeout = 30;
          };
          networks = lib.listToAttrs (map (iface:
            lib.nameValuePair "40-${iface}-initrd" {
              matchConfig.Name = iface;
              networkConfig.DHCP = cfg.network.dhcp;
              linkConfig.RequiredForOnline = "routable";
            })
          cfg.interface);
        };
      };
      services.resolved.enable = true;
    };

    systemd.network.networks = lib.listToAttrs (map (iface:
      lib.nameValuePair "40-${iface}" {
        matchConfig.Name = iface;
        networkConfig.KeepConfiguration = "yes";
      })
    cfg.interface);

    systemd.sleep.extraConfig = ''
      [Sleep]
      AllowSuspend=no
      AllowHibernation=no
      AllowHybridSleep=no
      AllowSuspendThenHibernate=no
    '';

    environment.systemPackages = with pkgs;
      []
      ++ lib.optionals cfg.nvmf.enable [nvme-cli]
      ++ lib.optionals cfg.iscsi.enable [openiscsi];
  };
}
