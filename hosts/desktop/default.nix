{
  config,
  pkgs,
  lib,
  ...
} @ args:
#############################################################
#
#  Ai - my main computer, with NixOS + I5-13600KF + RTX 4090 GPU, for gaming & daily use.
#
#############################################################
{
  imports = [
    ./cifs-mount.nix

    # netboot
    ./netboot.nix

    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../../nixos/fhs-fonts.nix
    ../../nixos/libvirt.nix
    ../../nixos/core-desktop.nix
    ../../nixos/user-group.nix

    ../../secrets/nixos.nix
  ];

  boot.kernelPackages = lib.mkForce pkgs.linux_mlx;

  # Enable binfmt emulation of aarch64-linux, this is required for cross compilation.
  boot.binfmt.emulatedSystems = ["aarch64-linux" "riscv64-linux"];
  # supported fil systems, so we can mount any removable disks with these filesystems
  boot.supportedFilesystems = [
    "ext4"
    "btrfs"
    "xfs"
    #"zfs"
    "ntfs"
    "fat"
    "vfat"
    "exfat"
    "cifs" # mount windows share
    "nfs"
  ];

  # Bootloader.
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi"; # ← use the same mount point here.
    };
    systemd-boot.enable = true;
  };

  networking = {
    hostName = "desktop";
    wireless.enable = false; # Enables wireless support via wpa_supplicant.

    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    networkmanager.enable = true;
    networkmanager.unmanaged = ["*,except:interface-name:wl*"];

    # enableIPv6 = false; # disable ipv6
    # interfaces.enp5s0 = {
    #   useDHCP = false;
    #   ipv4.addresses = [
    #     {
    #       address = "192.168.5.100";
    #       prefixLength = 24;
    #     }
    #   ];
    # };
    # defaultGateway = "192.168.5.201";
    # nameservers = [
    #   "119.29.29.29" # DNSPod
    #   "223.5.5.5" # AliDNS
    # ];
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
    };
    networks = {
      # Connect the bridge ports to the bridge
      "30-enp3s0" = {
        matchConfig.Name = "enp3s0";
        networkConfig.Bridge = "br0";
        linkConfig.RequiredForOnline = "enslaved";
      };

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
    };
  };

  # for Nvidia GPU
  services.xserver.videoDrivers = ["nvidia"]; # will install nvidia-vaapi-driver by default
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    forceFullCompositionPipeline = true;
    open = true;
    #powerManagement.enable = true;
  };
  # virtualisation.docker.enableNvidia = true; # for nvidia-docker

  hardware = {
    opengl = {
      enable = true;
      # if hardware.opengl.driSupport is enabled, mesa is installed and provides Vulkan for supported hardware.
      driSupport = true;
      # needed by nvidia-docker
      driSupport32Bit = true;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
