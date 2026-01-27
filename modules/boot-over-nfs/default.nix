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
  mountOptionsStr = concatStringsSep "," cfg.nfs.mountOptions;
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

        mountOptions = mkOption {
          type = types.listOf types.str;
          default = ["vers=4.2" "proto=rdma" "port=20049" "ro" "nolock" "noatime"];
          description = "Mount options for NFS root (using RDMA).";
        };
      };

      boot = {
        kernelModules = mkOption {
          type = types.listOf types.str;
          default = ["nfs" "sunrpc" "xprtrdma"];
          description = "Extra initrd kernel modules needed for NFS over RDMA boot.";
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
      kernelParams =
        [
          "ip=dhcp"
        ]
        ++ cfg.boot.extraKernelParams;

      initrd = {
        supportedFilesystems = ["nfs"];
        kernelModules = cfg.boot.kernelModules;
        network = {
          enable = true;
          flushBeforeStage2 = false;
        };
        systemd = {
          enable = true;
          emergencyAccess = true;
          initrdBin = [pkgs.iproute2 pkgs.pciutils pkgs.dnsutils pkgs.util-linuxMinimal pkgs.coreutils pkgs.iputils];

          services.ensure-network = {
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

          network = {
            enable = true;
            networks = {
              "40-${cfg.interface}" = {
                matchConfig.Name = cfg.interface;
                networkConfig.DHCP = cfg.network.dhcp;
                linkConfig.RequiredForOnline = "no";
              };
            };
          };
        };
        services.resolved.enable = true;
      };
    };

    systemd.network.networks."40-${cfg.interface}" = lib.mkForce {};

    fileSystems = {
      "/nix/store" = {
        device = "${cfg.nfs.server}:${cfg.nfs.rootPath}";
        fsType = "nfs";
        neededForBoot = true;
        options = cfg.nfs.mountOptions;
      };
    };

    environment.systemPackages = with pkgs; [nfs-utils];
  };
}
