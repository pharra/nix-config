{
  config,
  pkgs,
  lib,
  ...
} @ args: {
  imports = [
    ./hardware-configuration.nix
    ../../nixos/user-group.nix
  ];

  boot.iscsi-initiatord = {
    name = "iqn.2020-08.org.linux-iscsi.initiatorhost:installer";
    discoverPortal = "192.168.29.1";
    target = "iqn.2016-06.io.spdk:nixosefi";
  };

  hardware.mlx5 = {
    enable = true;
  };

  boot.nvmf = {
    enable = true;
    address = "192.168.29.1";
    target = "nqn.2016-06.io.spdk:nixos";
    type = "rdma";
    multipath = false;
    multiAddress = "192.168.28.1";
  };

  boot.extraModprobeConfig = "options mlx4_core msi_x=1 enable_4k_uar=1 enable_qos=1 log_num_mac=7 log_num_mgm_entry_size=-1 log_mtts_per_seg=4";

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
            matchConfig.Name = "enp0s3*";
            networkConfig = {
              # start a DHCP Client for IPv4 Addressing/Routing
              DHCP = "ipv4";
              # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
              IPv6AcceptRA = true;
              Domains = ["lan"];
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

  system.stateVersion = config.system.nixos.release;
}
