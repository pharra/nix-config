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
    #ib = "ibp66s0";
    eth-to-bridge = "eno2";
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
    ../../nixos/aosp.nix
    ../../nixos/ccache.nix
    ../../nixos/tailscale.nix
    ../../nixos/ddns-go.nix
    ../../nixos/nixvirt.nix
  ];

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
  boot.zfs.package = pkgs.zfs_unstable;
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

  services.duplicati = {
    enable = true;
    interface = "192.168.30.1";
  };

  services.keaWithDDNS = {
    enable = true;
    IPMasquerade = true;
    onlySLAAC = false;
    networks = {
      ib = {
        name = "ib";
        interface = interface.ib;
        domain = "ib";
        ipv4 = {
          subnet = "192.168.30.0/24";
          address = "192.168.30.1";
          netmask = "24";
          pools = [
            "192.168.30.50 - 192.168.30.150"
          ];
          reservations = [
            {
              hw-address = "50:65:f3:8a:c7:71";
              ip-address = "192.168.30.1";
              hostname = "homelab";
            }
          ];
        };
        ipv6 = {
          subnet = "fd00:0:30::/64";
          address = "fd00:0:30::1";
          netmask = "64";
          prefix = "fd00:0:30::";
          delegated-len = "64";
          id = 443;
          pools = [
            "fd00:0:30::/64"
          ];
          reservations = [
            {
              hw-address = "50:65:f3:8a:c7:71";
              ip-addresses = ["fd00:0:30::1"];
              hostname = "homelab";
            }
          ];
        };
      };

      eth = {
        name = "eth";
        interface = interface.eth;
        domain = "eth";
        ipv4 = {
          subnet = "192.168.29.0/24";
          address = "192.168.29.1";
          netmask = "24";
          pools = [
            "192.168.29.50 - 192.168.29.150"
          ];
          reservations = [
            {
              hw-address = "50:65:f3:8a:c7:72";
              ip-address = "192.168.29.1";
              hostname = "homelab";
            }
          ];
        };
        ipv6 = {
          subnet = "fd00:0:29::/64";
          address = "fd00:0:29::1";
          netmask = "64";
          prefix = "fd00:0:29::";
          delegated-len = "64";
          id = 444;
          pools = [
            "fd00:0:29::/64"
          ];
          reservations = [
            {
              hw-address = "50:65:f3:8a:c7:72";
              ip-addresses = ["fd00:0:29::1"];
              hostname = "homelab";
            }
          ];
        };
      };

      intern = {
        name = "intern";
        interface = interface.intern;
        domain = "intern";
        ipv4 = {
          subnet = "192.168.28.0/24";
          address = "192.168.28.1";
          netmask = "24";
          pools = [
            "192.168.28.50 - 192.168.28.150"
          ];
          reservations = [
            {
              hw-address = "7a:a6:c9:f3:65:a9";
              ip-address = "192.168.28.1";
              hostname = "homelab";
            }
          ];
        };
        ipv6 = {
          subnet = "fd00:0:28::/64";
          address = "fd00:0:28::1";
          prefix = "fd00:0:28::";
          delegated-len = "64";
          netmask = "64";
          id = 445;
          pools = [
            "fd00:0:28::/64"
          ];
          reservations = [
            {
              hw-address = "7a:a6:c9:f3:65:a9";
              ip-addresses = ["fd00:0:28::1"];
              hostname = "homelab";
            }
          ];
        };
      };
    };
    DNSForward = [
      {
        zone = ".";
        method = "udp";
        udp = {
          ip = "192.168.31.1";
        };
      }
    ];
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = "1";
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = "1";
  networking.firewall.interfaces = {
    "${interface.ib}" = {
      allowedTCPPortRanges = [
        {
          from = 0;
          to = 65535;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 0;
          to = 65535;
        }
      ];
    };
    "${interface.eth}" = {
      allowedTCPPortRanges = [
        {
          from = 0;
          to = 65535;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 0;
          to = 65535;
        }
      ];
    };
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
      "30-eno2" = {
        matchConfig.Name = "eno2";
        networkConfig.Bridge = "br1";
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
    #open = true;
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
