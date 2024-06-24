{
  config,
  lib,
  pkgs,
  ...
}: {
  boot.iscsi-initiatord = {
    name = "iqn.2023-11.org.nixos:desktop";
    discoverPortal = "homelab.local";
    target = "iqn.2016-06.io.spdk:nixosefi";
  };

  boot.nvmf = {
    enable = true;
    address = "192.168.29.1";
    target = "nqn.2016-06.io.spdk:nixos";
  };

  boot.initrd = {
    kernelModules = ["hv_vmbus" "hv_netvsc" "hv_storvsc" "virtio" "virtio_pci " "virtio_blk" "virtio_net" "nvme-rdma" "nvme-tcp"];
    systemd = {
      enable = true;
      emergencyAccess = true;
      initrdBin = [pkgs.iproute2 pkgs.pciutils pkgs.dnsutils pkgs.nvme-cli];
      dbus.enable = true;
      network = {
        enable = true;
        wait-online.anyInterface = true;
        networks = {
          # Configure the bridge for its desired function
          "40-eth" = {
            matchConfig.Name = "*d1";
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

  services.resolved = {
    extraConfig = ''
      MulticastDNS=yes
    '';
    enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      openiscsi
    ];
  };
}
