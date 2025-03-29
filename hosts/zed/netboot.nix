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
    name = "iqn.2020-08.org.linux-iscsi.initiatorhost:zed";
    discoverPortal = "192.168.29.1";
    target = "iqn.2016-06.io.spdk:zednixosefi";
  };

  boot.nvmf = {
    enable = true;
    address = "192.168.29.1";
    target = "nqn.2016-06.io.spdk:zed_nixos";
    type = "rdma";
  };

  boot.initrd = {
    kernelModules = ["nvme-rdma" "nvme-tcp"];
    systemd = {
      enable = true;
      emergencyAccess = true;
      initrdBin = [pkgs.iproute2 pkgs.pciutils pkgs.dnsutils pkgs.nvme-cli];
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

  fileSystems."/" = lib.mkForce {
    device = "/dev/disk/by-label/zed_nixos";
    fsType = "ext4";
    neededForBoot = true;
  };

  fileSystems."/boot/efi" = lib.mkForce {
    device = "/dev/disk/by-label/zed_boot";
    fsType = "vfat";
  };

  environment = {
    systemPackages = with pkgs; [
      openiscsi
      nvme-cli
    ];
  };
}
