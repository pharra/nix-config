{
  config,
  pkgs,
  lib,
  interface,
  ...
} @ args: {
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
        enable = false;
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
              Domains = ["local"];
              MulticastDNS = true;
            };
            dhcpV4Config = {
              UseDomains = true;
            };
            ipv6AcceptRAConfig = {
              UseDNS = true;
              UseDomains = true;
            };
            linkConfig = {
              # or "routable" with IP addresses configured
              RequiredForOnline = "routable";
              Multicast = true;
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

  environment = {
    systemPackages = with pkgs; [
      openiscsi
      nvme-cli
    ];
  };
}
