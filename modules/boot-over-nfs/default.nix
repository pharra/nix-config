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
  primaryPeer = builtins.head cfg.nfs.multipathPeers;
  primaryInterface = builtins.head cfg.interface;
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

      interface = mkOption {
        type = types.listOf types.str;
        default = ["eth0"];
        description = "Network interfaces to bring up in initrd (first entry is used as primary).";
      };

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
      kernelParams = cfg.boot.extraKernelParams ++ ["nohibernate" "mem_sleep_default=shallow"];

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
                ExecStart = "${pkgs.bashInteractive}/bin/sh -c 'until ${pkgs.iputils}/bin/ping -c 1 ${primaryPeer.serverIp}; do ${pkgs.coreutils}/bin/sleep 1; done'";
              };
            };
          };

          network = {
            enable = true;
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
    };

    systemd.network.networks = lib.listToAttrs (map (iface:
      lib.nameValuePair "40-${iface}" {
        matchConfig.Name = iface;
        linkConfig = {
          Unmanaged = true;
        };
      })
    cfg.interface);

    systemd.targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };

    systemd.tmpfiles.rules = [
      "z /sys/power/state 0444 root root -"
      "z /sys/power/disk 0444 root root -"
    ];

    fileSystems = let
      extraPeers = lib.drop 1 cfg.nfs.multipathPeers;
      multipathFileSystems = lib.listToAttrs (lib.imap0 (idx: peer:
        lib.nameValuePair "/nix/store-mp-${toString (idx + 1)}" {
          device = "${peer.serverIp}:${cfg.nfs.rootPath}";
          fsType = "nfs";
          neededForBoot = true;
          options = mountOptions ++ ["clientaddr=${peer.clientIp}"];
        })
      extraPeers);
    in
      {
        "/nix/store" = {
          device = "${primaryPeer.serverIp}:${cfg.nfs.rootPath}";
          fsType = "nfs";
          neededForBoot = true;
          options = mountOptions ++ ["clientaddr=${primaryPeer.clientIp}"];
        };
      }
      // multipathFileSystems;
  };
}
