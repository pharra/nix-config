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
let
  interface = {
    mlx5_0 = "mlx5_0";
  };
  interfaces = [
    {
      mac = "9c:52:f8:8e:dd:d8";
      name = "mlx5_0";
    }
    {
      mac = "9c:52:f8:8e:dd:d9";
      name = "enp5s0";
    }
  ];
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./cifs-mount.nix

    ../../nixos/impermanence.nix

    ../../nixos/libvirt.nix
    ../../nixos/core-desktop.nix
    ../../nixos/user-group.nix

    ../../secrets/nixos.nix
    ./nixvirt
    (import ./netboot.nix {
      inherit config pkgs lib;
      interface = interface.mlx5_0;
    })
    #../../nixos/ccache.nix
  ];

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
    hostName = "fluent";
    domain = "lan";
    wireless.enable = false; # Enables wireless support via wpa_supplicant.

    hostId = "88fcb8e9";
  };

  networking.firewall.enable = lib.mkForce false;

  net-name = {
    enable = true;
    inherit interfaces;
  };

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
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
      "30-enp5s0" = {
        matchConfig.Name = "enp5s0";
        networkConfig.Bridge = "br0";
        linkConfig.RequiredForOnline = "enslaved";
      };

      "40-br0" = {
        matchConfig.Name = "br0";
        bridgeConfig = {};
        networkConfig = {
          # start a DHCP Client for IPv4 Addressing/Routing
          DHCP = "ipv4";
          # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
          IPv6AcceptRA = true;
          MulticastDNS = true;
          Domains = ["local"];
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

      "40-${interface.mlx5_0}" = {
        matchConfig.Name = "${interface.mlx5_0}";
        networkConfig = {
          # start a DHCP Client for IPv4 Addressing/Routing
          DHCP = "ipv4";
          # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
          IPv6AcceptRA = true;
          MulticastDNS = true;
          Domains = ["local"];
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

  systemd.services."systemd-suspend" = {
    serviceConfig = {
      Environment = ''"SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false"'';
    };
  };

  services.xserver.videoDrivers = ["nvidia"]; # will install nvidia-vaapi-driver by default

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = true;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = false;
      };
      # Make sure to use the correct Bus ID values for your system!
      # intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
      amdgpuBusId = "PCI:7:0:0"; # For AMD GPU
    };
    # # Fine-grained power management. Turns off GPU when not in use.
    # # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = true;
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
