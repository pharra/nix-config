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
  netboot = import ../netboot-root-common.nix {inherit lib pkgs;};
  nfsPort =
    if cfg.nfs.transport == "rdma"
    then 20049
    else 2049;
  primaryPeer = builtins.head cfg.nfs.multipathPeers;
  mountOptions =
    [
      "vers=4.2"
      "rw"
      "noatime"
      "noresvport"
      "hard"
      "sync"
      "nconnect=8"
      "trunkdiscovery"
    ]
    ++ lib.optional (cfg.nfs.transport == "rdma") "proto=rdma"
    ++ lib.optional (cfg.nfs.transport == "rdma") "port=${toString nfsPort}";
in {
  options = {
    services.nfs-root = {
      enable = mkEnableOption "NFS root boot (guest side)";

      interface = netboot.interfaceOption ["eth0"];

      nfs = {
        transport = mkOption {
          type = types.enum ["tcp" "rdma"];
          default = "tcp";
          description = "NFS transport protocol (tcp or rdma).";
        };

        multipathPeers = mkOption {
          type = types.listOf (types.submodule {
            options = {
              clientIp = mkOption {
                type = types.str;
                description = "Client IP address used for clientaddr (session trunking).";
              };

              serverIp = mkOption {
                type = types.str;
                description = "NFS server IP address for this path.";
              };
            };
          });
          default = [];
          description = "List of client/server IP pairs for NFS multipath (session trunking). The first entry is used for /nix/store; remaining entries create extra fileSystems mount points.";
        };

        rootPath = mkOption {
          type = types.str;
          default = "/nix/store";
          description = "NFS export path used as /nix/store.";
        };
      };

      boot = netboot.bootOptions {kernelModulesDefault = ["nfs" "sunrpc" "nfsv4"];};

      network = netboot.networkOption;
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.nfs.multipathPeers != [];
        message = "services.nfs-root.nfs.multipathPeers must have at least one client/server pair.";
      }
    ];

    boot = {
      loader = {
        efi.canTouchEfiVariables = lib.mkForce false;
        systemd-boot.graceful = true;
      };
      supportedFilesystems = ["nfs"];
      kernelParams = cfg.boot.extraKernelParams;

      initrd = {
        supportedFilesystems = ["nfs"];
        kernelModules =
          lib.mkAfter (cfg.boot.kernelModules
            ++ lib.optional (cfg.nfs.transport == "rdma") "xprtrdma");
        systemd =
          (netboot.initrdSystemd {extraInitrdBin = [pkgs.nfs-utils];})
          // {
            services = {
              ensure-network-nfs = netboot.ensureNetwork {peerAddress = primaryPeer.serverIp;};
            };
            network = netboot.initrdNetwork cfg;
          };
        services.resolved.enable = true;
      };
    };

    systemd.network.networks = netboot.stage2Network cfg;

    fileSystems = let
      multipathFileSystems = lib.listToAttrs (lib.imap0 (idx: peer:
        lib.nameValuePair "/nix" {
          device = "${peer.serverIp}:${cfg.nfs.rootPath}";
          fsType = "nfs";
          neededForBoot = true;
          options = mountOptions ++ ["clientaddr=${peer.clientIp}"];
        })
      cfg.nfs.multipathPeers);
    in
      multipathFileSystems;
  };
}
