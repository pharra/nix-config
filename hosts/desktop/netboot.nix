{
  config,
  lib,
  pkgs,
  ...
}: {
  boot.iscsi-initiatord = {
    name = "iqn.2023-11.org.nixos:desktop";
    discoverPortal = "192.168.29.1";
    target = "iqn.2016-06.io.spdk:nixosefi";
  };

  boot.nvmf = {
    enable = true;
    address = "192.168.29.1";
    target = "nqn.2016-06.io.spdk:nixos";
    type = "rdma";
    multipath = false;
    multiAddress = "192.168.28.1";
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
        wait-online.extraArgs = ["--ipv4" "--ipv6" "--interface=enp0s3"];
        networks = {
          # Configure the bridge for its desired function
          "40-eth" = {
            matchConfig.Name = "!lo";
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
              Multicast = true;
              MTUBytes = "9000";
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
      nvme-cli
    ];
  };
}
