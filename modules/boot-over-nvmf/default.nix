{
  config,
  pkgs,
  lib,
  interface,
  ...
}:
with lib; let
  cfg = config.services.nvmf-root;
in {
  options = {
    services.nvmf-root = {
      enable = mkEnableOption "NVMf root service";

      interface = mkOption {
        type = types.str;
        default = "mlx5_0";
        description = "The network interface to use for NVMf root.";
      };

      nvmf = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable NVMf boot.";
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

        type = mkOption {
          type = types.str;
          default = "rdma";
          description = "The NVMf transport type (rdma, tcp, etc).";
        };
      };

      iscsi = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable iSCSI boot.";
        };

        name = mkOption {
          type = types.str;
          default = "iqn.2020-08.org.linux-iscsi.initiatorhost:fluent";
          description = "The iSCSI initiator name.";
        };

        discoverPortal = mkOption {
          type = types.str;
          default = "192.168.29.1";
          description = "The iSCSI discovery portal address.";
        };

        target = mkOption {
          type = types.str;
          default = "iqn.2016-06.io.spdk:fluentnixosefi";
          description = "The iSCSI target name.";
        };
      };

      tmpfsRoot = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable tmpfs root using ramdisk.";
        };

        sourceLabel = mkOption {
          type = types.str;
          default = "fluent_nix";
          description = "The disk label to copy to ramdisk.";
        };

        ramdiskDevice = mkOption {
          type = types.str;
          default = "/dev/ram0";
          description = "The ramdisk device to use.";
        };

        blockSize = mkOption {
          type = types.str;
          default = "4M";
          description = "Block size for dd operation.";
        };

        fsType = mkOption {
          type = types.str;
          default = "btrfs";
          description = "Filesystem type for the ramdisk.";
        };

        mountOptions = mkOption {
          type = types.listOf types.str;
          default = ["compress=zstd"];
          description = "Mount options for the ramdisk filesystem.";
        };
      };

      zfs = {
        poolName = mkOption {
          type = types.str;
          default = "fluent";
          description = "ZFS pool name.";
        };

        datasets = mkOption {
          type = types.attrsOf (types.submodule {
            options = {
              mountPoint = mkOption {
                type = types.str;
                description = "Mount point for the dataset.";
              };

              dataset = mkOption {
                type = types.str;
                description = "ZFS dataset path (relative to pool).";
              };

              neededForBoot = mkOption {
                type = types.bool;
                default = true;
                description = "Whether this dataset is needed for boot.";
              };
            };
          });
          default = {
            system = {
              mountPoint = "/system";
              dataset = "";
              neededForBoot = true;
            };
            tmp = {
              mountPoint = "/tmp";
              dataset = "tmp";
              neededForBoot = true;
            };
            nix = {
              mountPoint = "/nix";
              dataset = "nix";
              neededForBoot = true;
            };
            "nix-var" = {
              mountPoint = "/nix/var";
              dataset = "nix/var";
              neededForBoot = true;
            };
            "nix-persistent" = {
              mountPoint = "/nix/persistent";
              dataset = "nix/persistent";
              neededForBoot = true;
            };
          };
          description = "ZFS datasets to mount.";
        };
      };

      boot = {
        efiLabel = mkOption {
          type = types.str;
          default = "fluent_boot";
          description = "The disk label for the EFI partition.";
        };

        kernelModules = mkOption {
          type = types.listOf types.str;
          default = ["brd" "btrfs"];
          description = "Additional kernel modules to load in initrd.";
        };
      };

      network = {
        dhcp = mkOption {
          type = types.str;
          default = "ipv4";
          description = "DHCP configuration (ipv4, ipv6, yes, no).";
        };

        ipv6AcceptRA = mkOption {
          type = types.bool;
          default = true;
          description = "Accept IPv6 Router Advertisements.";
        };

        domains = mkOption {
          type = types.listOf types.str;
          default = ["mlx"];
          description = "Search domains for DNS.";
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
    boot.iscsi-initiatord = mkIf cfg.iscsi.enable {
      name = cfg.iscsi.name;
      discoverPortal = cfg.iscsi.discoverPortal;
      target = cfg.iscsi.target;
    };

    boot.nvmf = {
      enable = cfg.nvmf.enable;
      address = cfg.nvmf.address;
      target = cfg.nvmf.target;
      type = cfg.nvmf.type;
    };

    boot.initrd = {
      kernelModules = cfg.boot.kernelModules;
      systemd = {
        enable = true;
        emergencyAccess = true;
        initrdBin = [pkgs.iproute2 pkgs.pciutils pkgs.dnsutils pkgs.util-linuxMinimal pkgs.coreutils pkgs.iputils];

        services.nix-tmpfs-root = mkIf cfg.tmpfsRoot.enable {
          enable = true;
          requiredBy = ["initrd.target"];
          after = ["nixos-iscsi.service" "sysroot-system.mount"];
          wants = ["nixos-iscsi.service" "sysroot-system.mount"];
          before = ["initrd-find-nixos-closure.service"];
          serviceConfig = {
            Type = "oneshot";
            ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /sysroot/nix/store";
            ExecStart = [
              "${pkgs.coreutils}/bin/dd if=/dev/disk/by-label/${cfg.tmpfsRoot.sourceLabel} of=${cfg.tmpfsRoot.ramdiskDevice} bs=${cfg.tmpfsRoot.blockSize} iflag=direct oflag=direct"
              "${pkgs.util-linuxMinimal}/bin/mount -t ${cfg.tmpfsRoot.fsType} -o ${lib.concatStringsSep "," cfg.tmpfsRoot.mountOptions} ${cfg.tmpfsRoot.ramdiskDevice} /sysroot/nix/store"
            ];
          };
        };

        services.ensure-network = {
          enable = true;
          before = ["network-online.target"];
          wantedBy = ["network-online.target"];
          after = ["nss-lookup.target"];
          unitConfig = {
            DefaultDependencies = "no";
          };
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.bashInteractive}/bin/sh -c 'until ${pkgs.iputils}/bin/ping -c 1 ${cfg.network.pingHost}; do ${pkgs.coreutils}/bin/sleep 1; done'";
          };
        };

        dbus.enable = true;
        network = {
          enable = true;
          networks = {
            # Configure the interface
            "40-${cfg.interface}" = {
              matchConfig.Name = "${cfg.interface}";
              networkConfig = {
                DHCP = cfg.network.dhcp;
                IPv6AcceptRA = cfg.network.ipv6AcceptRA;
                Domains = cfg.network.domains;
              };
              dhcpV4Config = {
                UseDomains = true;
              };
              ipv6AcceptRAConfig = {
                UseDNS = true;
                UseDomains = true;
              };
              linkConfig = {
                RequiredForOnline = "routable";
              };
            };
          };
        };
      };
      services.resolved.enable = true;
    };

    systemd.network.networks = {
      "40-${cfg.interface}" = lib.mkForce {};
    };

    # Generate ZFS filesystem configurations dynamically
    fileSystems = lib.mkMerge [
      (lib.mapAttrs' (
          name: dataset:
            lib.nameValuePair dataset.mountPoint (lib.mkForce {
              device =
                if dataset.dataset == ""
                then cfg.zfs.poolName
                else "${cfg.zfs.poolName}/${dataset.dataset}";
              fsType = "zfs";
              neededForBoot = dataset.neededForBoot;
              options = ["zfsutil"];
            })
        )
        cfg.zfs.datasets)

      # EFI boot partition
      {
        "/boot/efi" = lib.mkForce {
          device = "/dev/disk/by-label/${cfg.boot.efiLabel}";
          fsType = "vfat";
        };
      }
    ];

    environment = {
      systemPackages = with pkgs; [
        openiscsi
        nvme-cli
      ];
    };
  };
}
