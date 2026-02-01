# Guest module: Configure this NixOS to boot from NFS root
# This module is used on the guest machine that will boot via NFS
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nfs-root;
  nfsPort =
    if cfg.nfs.transport == "rdma"
    then 20049
    else 2049;
  mountOptions =
    [
      "vers=4.2"
      "ro"
      "noatime"
    ]
    ++ lib.optional (cfg.nfs.transport == "rdma") "proto=rdma"
    ++ lib.optional (cfg.nfs.transport == "rdma") "port=${toString nfsPort}";
in {
  options = {
    services.nfs-root = {
      enable = mkEnableOption "NFS root boot (guest side)";

      interface = mkOption {
        type = types.str;
        default = "eth0";
        description = "Network interface to bring up in initrd.";
      };

      nfs = {
        transport = mkOption {
          type = types.enum ["tcp" "rdma"];
          default = "tcp";
          description = "NFS transport protocol (tcp or rdma).";
        };

        server = mkOption {
          type = types.str;
          default = "192.168.29.1";
          description = "NFS server IP or hostname.";
        };

        rootPath = mkOption {
          type = types.str;
          default = "/nix/store";
          description = "NFS export path used as /nix/store.";
        };
      };

      boot = {
        kernelModules = mkOption {
          type = types.listOf types.str;
          default = ["nfs" "sunrpc" "nfsv4"];
          description = "Extra initrd kernel modules needed for NFS boot.";
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
      };
    };
  };

  config = mkIf cfg.enable {
    boot = {
      supportedFilesystems = ["nfs"];
      kernelParams = cfg.boot.extraKernelParams;

      initrd = {
        supportedFilesystems = ["nfs"];
        kernelModules =
          lib.mkAfter (cfg.boot.kernelModules
            ++ lib.optional (cfg.nfs.transport == "rdma") "xprtrdma");
        systemd = {
          enable = true;
          emergencyAccess = true;
          initrdBin = [pkgs.iproute2 pkgs.pciutils pkgs.dnsutils pkgs.util-linux pkgs.coreutils pkgs.iputils pkgs.nfs-utils];

          services = {
            ensure-network = {
              enable = true;
              before = ["network-online.target"];
              wantedBy = ["network-online.target"];
              after = ["nss-lookup.target"];
              unitConfig.DefaultDependencies = "no";
              serviceConfig = {
                Type = "oneshot";
                ExecStart = "${pkgs.bashInteractive}/bin/sh -c 'until ${pkgs.iputils}/bin/ping -c 1 ${cfg.nfs.server}; do ${pkgs.coreutils}/bin/sleep 1; done'";
              };
            };
          };

          network = {
            enable = true;
            networks = {
              "40-${cfg.interface}-initrd" = {
                matchConfig.Name = cfg.interface;
                networkConfig.DHCP = cfg.network.dhcp;
                linkConfig.RequiredForOnline = "routable";
              };
            };
          };
        };
        services.resolved.enable = true;
      };
    };

    systemd.network.networks."40-${cfg.interface}" = {
      matchConfig.Name = cfg.interface;
      linkConfig = {
        Unmanaged = true;
      };
    };

    fileSystems = {
      "/nix/store" = {
        device = "${cfg.nfs.server}:${cfg.nfs.rootPath}";
        fsType = "nfs";
        neededForBoot = true;
        options = mountOptions;
      };
    };
  };
}
