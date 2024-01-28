{
  config,
  lib,
  pkgs,
  libs,
  netboot_args,
  ...
} @ args: let
  interface = {
    ib = "enp66s0";
    eth-to-bridge = "enp66s0d1";
    eth = "enp66s0d1";
    intern = "br1";
  };
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../../nixos/fhs-fonts.nix
    ../../nixos/libvirt.nix
    ../../nixos/core-desktop.nix
    # ../../nixos/remote-building.nix
    ../../nixos/user-group.nix

    ../../nixos/impermanence.nix

    ../../nixos/spdk.nix

    ../../nixos/iscsi-server

    (import ../../nixos/samba.nix {inherit config lib interface pkgs libs;})

    (import ../../nixos/ipxe {inherit config lib interface pkgs libs netboot_args;})
    ../../nixos/mlx-sriov.nix

    ../../secrets/nixos.nix

    ../../nixos/sftp-server.nix
    ../../nixos/media-server.nix
    ../../nixos/caddy.nix
  ];

  boot.kernelPackages = lib.mkForce pkgs.linux_mlx;

  # Enable binfmt emulation of aarch64-linux, this is required for cross compilation.
  boot.binfmt.emulatedSystems = ["aarch64-linux" "riscv64-linux"];
  # supported fil systems, so we can mount any removable disks with these filesystems
  boot.supportedFilesystems = [
    "ext4"
    "btrfs"
    "xfs"
    "zfs"
    "ntfs"
    "fat"
    "vfat"
    "exfat"
    "cifs" # mount windows share
  ];

  networking.hostId = "88fcb8e5";
  boot.zfs.enableUnstable = true;
  boot.zfs.extraPools = ["data"];
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  # raid
  boot.swraid.enable = true;
  boot.swraid.mdadmConf = "ARRAY /dev/md0 metadata=1.2 spares=1 name=homelab:0 UUID=c8e5fbbe:edd3c686:a1e53f13:e3922146";

  # Bootloader.
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi"; # ← use the same mount point here.
    };
    systemd-boot.enable = true;
  };

  systemd.services = {
    tune-usb-autosuspend = {
      description = "Disable USB autosuspend";
      wantedBy = ["multi-user.target"];
      serviceConfig = {Type = "oneshot";};
      unitConfig.RequiresMountsFor = "/sys";
      script = ''
        echo -1 > /sys/module/usbcore/parameters/autosuspend
      '';
    };
  };

  systemd.network = {
    enable = true;
    netdevs = {
      # Create the bridge interface
      "20-br0" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "br0";
        };
      };

      "30-br1" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "br1";
        };
      };
    };
    networks = {
      # Connect the bridge ports to the bridge
      "30-eno1" = {
        matchConfig.Name = "eno1";
        networkConfig.Bridge = "br0";
        linkConfig.RequiredForOnline = "enslaved";
      };
      # "30-enp129s0" = {
      #   matchConfig.Name = "enp129s0";
      #   networkConfig.Bridge = "br1";
      #   linkConfig.RequiredForOnline = "enslaved";
      # };
      # "30-${interface.eth-to-bridge}" = {
      #   matchConfig.Name = "${interface.eth-to-bridge}";
      #   networkConfig.Bridge = "br1";
      #   linkConfig.RequiredForOnline = "enslaved";
      # };

      # Configure the bridge for its desired function
      "40-br0" = {
        matchConfig.Name = "br0";
        bridgeConfig = {};
        networkConfig = {
          # start a DHCP Client for IPv4 Addressing/Routing
          DHCP = "ipv4";
          # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
          IPv6AcceptRA = true;
        };
        linkConfig = {
          # or "routable" with IP addresses configured
          RequiredForOnline = "routable";
        };
      };

      # internal network
      "40-${interface.intern}" = {
        matchConfig.Name = "${interface.intern}";
        # bridgeConfig = {};
        networkConfig = {
          Address = "192.168.28.1/24";
          # DHCPServer = true;
          IPMasquerade = "ipv4";
          ConfigureWithoutCarrier = true;
        };
        # dhcpServerConfig = {
        #   PoolOffset = 100;
        #   PoolSize = 20;
        # };
        linkConfig = {
          # or "routable" with IP addresses configured
          ActivationPolicy = "always-up";
          RequiredForOnline = "no";
        };
      };

      "50-${interface.ib}" = {
        matchConfig.Name = "${interface.ib}";
        # bridgeConfig = {};
        networkConfig = {
          Address = "192.168.30.1/24";
          # DHCPServer = true;
          IPMasquerade = "ipv4";
        };
        # dhcpServerConfig = {
        #   PoolOffset = 100;
        #   PoolSize = 20;
        # };
        linkConfig = {
          # or "routable" with IP addresses configured
          ActivationPolicy = "always-up";
        };
      };

      "50-${interface.eth}" = {
        matchConfig.Name = "${interface.eth}";
        bridgeConfig = {};
        networkConfig = {
          Address = "192.168.29.1/24";
          # DHCPServer = true;
          IPMasquerade = "ipv4";
        };
        # dhcpServerConfig = {
        #   PoolOffset = 100;
        #   PoolSize = 20;
        # };
        linkConfig = {
          # or "routable" with IP addresses configured
          ActivationPolicy = "always-up";
        };
      };
    };
  };

  networking = {
    hostName = "homelab";
    wireless.enable = false; # Enables wireless support via wpa_supplicant.

    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    networkmanager.enable = true;
    networkmanager.unmanaged = ["*,except:interface-name:wl*"];
  };

  # for Nvidia GPU
  services.xserver.videoDrivers = ["nvidia"]; # will install nvidia-vaapi-driver by default
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    forceFullCompositionPipeline = true;
    #powerManagement.enable = true;
  };
  # virtualisation.docker.enableNvidia = true; # for nvidia-docker

  hardware.opengl = {
    enable = true;
    # if hardware.opengl.driSupport is enabled, mesa is installed and provides Vulkan for supported hardware.
    driSupport = true;
    # needed by nvidia-docker
    driSupport32Bit = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
