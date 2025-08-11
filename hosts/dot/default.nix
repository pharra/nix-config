{
  config,
  pkgs,
  lib,
  ...
} @ args:
#############################################################
#
#  Surface Book 2
#
#############################################################
let
  interfaces = [
    {
      mac = "00:0e:c6:b6:1c:8d";
      name = "eno";
    }
    {
      mac = "c4:9d:ed:16:f2:01";
      name = "wlo";
    }
  ];
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../../nixos/libvirt.nix
    ../../nixos/core-desktop.nix
    ../../nixos/user-group.nix

    ../../secrets/nixos.nix

    ./nixvirt
  ];

  net-name = {
    enable = true;
    inherit interfaces;
  };

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

  systemd.sleep.extraConfig = ''
    [Sleep]
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';

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
      "30-eno" = {
        matchConfig.Name = "eno";
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

  networking = {
    hostName = "dot";
    wireless.enable = false; # Enables wireless support via wpa_supplicant.

    networkmanager.enable = true;
    networkmanager.unmanaged = ["*,except:interface-name:wl*"];
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
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
