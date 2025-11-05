{
  config,
  pkgs,
  lib,
  interface,
  boot_from_network ? false,
  ...
} @ args:
lib.mkIf boot_from_network {
  boot.iscsi-initiatord = {
    name = "iqn.2020-08.org.linux-iscsi.initiatorhost:fluent";
    discoverPortal = "192.168.29.1";
    target = "iqn.2016-06.io.spdk:fluentnixosefi";
  };

  boot.nvmf = {
    enable = false;
    address = "192.168.29.1";
    target = "nqn.2016-06.io.spdk:fluent_nixos";
    type = "rdma";
  };

  boot.initrd = {
    kernelModules = ["brd" "btrfs"];
    systemd = {
      enable = true;
      emergencyAccess = true;
      initrdBin = [pkgs.iproute2 pkgs.pciutils pkgs.dnsutils pkgs.util-linuxMinimal pkgs.coreutils pkgs.iputils];

      services.nix-tmpfs-root = {
        enable = true;
        requiredBy = ["initrd.target"];
        after = ["nixos-iscsi.service" "sysroot-system.mount"];
        wants = ["nixos-iscsi.service" "sysroot-system.mount"];
        before = ["initrd-find-nixos-closure.service"];
        serviceConfig = {
          Type = "oneshot";
          ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /sysroot/nix/store";
          ExecStart = [
            "${pkgs.coreutils}/bin/dd if=/dev/disk/by-label/fluent_nix of=/dev/ram0 bs=4M iflag=direct oflag=direct"
            "${pkgs.util-linuxMinimal}/bin/mount -t btrfs -o compress=zstd /dev/ram0 /sysroot/nix/store"
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
          ExecStart = "${pkgs.bashInteractive}/bin/sh -c 'until ${pkgs.iputils}/bin/ping -c 1 1.1.1.1; do ${pkgs.coreutils}/bin/sleep 1; done'";
        };
      };

      dbus.enable = true;
      network = {
        enable = true;
        networks = {
          # Configure the bridge for its desired function
          "40-${interface}" = {
            matchConfig.Name = "${interface}";
            networkConfig = {
              # start a DHCP Client for IPv4 Addressing/Routing
              DHCP = "ipv4";
              # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
              IPv6AcceptRA = true;
              Domains = ["mlx"];
            };
            dhcpV4Config = {
              UseDomains = true;
              UseRoutes = false;
            };
            ipv6AcceptRAConfig = {
              UseDNS = true;
              UseDomains = true;
            };
            linkConfig = {
              # or "routable" with IP addresses configured
              RequiredForOnline = "routable";
            };
          };
        };
      };
    };
    services.resolved.enable = true;
  };

  systemd.network.networks = {
    "40-${interface}" = lib.mkForce {};
  };

  fileSystems."/system" = lib.mkForce {
    device = "fluent";
    fsType = "zfs";
    neededForBoot = true;
    options = ["zfsutil"];
  };

  fileSystems."/tmp" = lib.mkForce {
    device = "fluent/tmp";
    fsType = "zfs";
    neededForBoot = true;
    options = ["zfsutil"];
  };

  fileSystems."/nix" = lib.mkForce {
    device = "fluent/nix";
    fsType = "zfs";
    neededForBoot = true;
    options = ["zfsutil"];
  };

  fileSystems."/nix/var" = lib.mkForce {
    device = "fluent/nix/var";
    fsType = "zfs";
    neededForBoot = true;
    options = ["zfsutil"];
  };

  fileSystems."/nix/persistent" = lib.mkForce {
    device = "fluent/nix/persistent";
    fsType = "zfs";
    neededForBoot = true;
    options = ["zfsutil"];
  };

  fileSystems."/boot/efi" = lib.mkForce {
    device = "/dev/disk/by-label/fluent_boot";
    fsType = "vfat";
  };

  environment = {
    systemPackages = with pkgs; [
      openiscsi
      nvme-cli
    ];
  };
}
