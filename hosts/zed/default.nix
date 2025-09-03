{
  config,
  pkgs,
  lib,
  boot_from_network ? false,
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
    net0 = "net0";
  };
  interfaces = [
    {
      mac = "9c:52:f8:8e:dd:d8";
      name = "mlx5_0";
    }
    {
      mac = "9c:52:f8:8e:dd:10";
      name = "mlx5_0";
    }
    {
      mac = "9c:52:f8:8e:dd:d9";
      name = "net0";
    }
    {
      mac = "58:47:ca:79:85:1c";
      name = "net0";
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
      inherit boot_from_network config pkgs lib;
      interface = interface.mlx5_0;
    })
    #../../nixos/ccache.nix

    ../../nixos/virtualisation
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
    hostName = "zed";
    domain = "lan";
    wireless.enable = false; # Enables wireless support via wpa_supplicant.

    hostId = "88fcb8e9";

    networkmanager.enable = true;
    networkmanager.unmanaged = ["*,except:interface-name:wl*"];
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
      "30-${interface.net0}" = {
        matchConfig.Name = "${interface.net0}";
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
          Domains = ["lan"];
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

  systemd.services = {
    ensure-network = {
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
    "systemd-suspend" = {
      serviceConfig = {
        Environment = ''"SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false"'';
      };
    };
  };

  services.xserver.videoDrivers = ["nvidia" "amdgpu"]; # will install nvidia-vaapi-driver by default

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  hardware.nvidia = {
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    powerManagement.enable = true;
  };

  fileSystems."/system" = {
    device = "system";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/tmp" = {
    device = "system/tmp";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/nix" = {
    device = "system/nix";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/nix/var" = {
    device = "system/nix/var";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/nix/persistent" = {
    device = "system/nix/persistent";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  systemd.sleep.extraConfig = ''
    [Sleep]
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
