{
  config,
  lib,
  pkgs,
  libs,
  mysecrets,
  netboot_args,
  ...
} @ args: let
  interface = {
    eth-to-bridge = "eno2";
    ib = "ib";
    eth = "mlx5_0";
    intern = "br1";
  };
  interfaces = [
    {
      mac = "50:65:f3:8a:c7:71";
      name = "mlx4_0";
    }
    {
      mac = "50:65:f3:8a:c7:72";
      name = "mlx4_1";
    }
    {
      mac = "f4:6b:8c:13:cf:e6";
      name = "mlx5_0";
    }
    {
      mac = "f4:6b:8c:13:cf:e7";
      name = "mlx5_1";
    }
  ];
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
    #    ../../nixos/ccache.nix
    ../../nixos/tailscale.nix
    ../../nixos/ddns-go.nix

    ../../nixos/virtualisation
    ../../nixos/scripts.nix

    ./nixvirt
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

  systemd.sleep.extraConfig = ''
    [Sleep]
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';

  networking.hostId = "88fcb8e5";
  boot.zfs.package = pkgs.zfs_unstable;
  boot.zfs.extraPools = ["data"];
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  networking.firewall.enable = lib.mkForce false;

  # services.proxmox-ve = {
  #   enable = true;
  #   ipAddress = "192.168.29.1";
  #   bridges = ["br0"];
  # };

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

  age.secrets."restic_password" = {
    file = "${mysecrets}/restic_password.age";
    mode = "777";
    path = "/etc/restic_password";
  };
  age.secrets."rclone_config" = {
    file = "${mysecrets}/rclone_config.age";
    mode = "777";
    path = "/etc/rclone_config.conf";
  };
  systemd.mounts = [
    {
      type = "rclone";
      what = "aliyundrive:/movies";
      where = "/share/media/aliyundrive/movies";
      mountConfig = {
        Options = "rw,gid=sftp,uid=sftp,allow_other,args2env,vfs-cache-mode=writes,config=${config.age.secrets.rclone_config.path}";
      };
    }
    {
      type = "rclone";
      what = "aliyundrive:/tv";
      where = "/share/media/aliyundrive/tv";
      mountConfig = {
        Options = "rw,gid=sftp,uid=sftp,allow_other,args2env,vfs-cache-mode=writes,config=${config.age.secrets.rclone_config.path}";
      };
    }
    {
      type = "rclone";
      what = "quark:/";
      where = "/share/media/quark";
      mountConfig = {
        Options = "rw,gid=sftp,uid=sftp,allow_other,args2env,vfs-cache-mode=writes,config=${config.age.secrets.rclone_config.path}";
      };
    }
  ];

  systemd.automounts = [
    {
      wantedBy = ["multi-user.target"];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      where = "/share/media/aliyundrive/movies";
    }
    {
      wantedBy = ["multi-user.target"];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      where = "/share/media/aliyundrive/tv";
    }
  ];
  services.restic.backups = {
    sftp_android = {
      user = "sftp";
      repository = "/share/restic";
      initialize = true; # initializes the repo, don't set if you want manual control
      passwordFile = config.age.secrets.restic_password.path;
      paths = ["/share/sftp/Android"];
      timerConfig = {
        OnCalendar = "03:00";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };

    aliyundrive_android = {
      user = "sftp";
      repository = "rclone:aliyundrive:restic";
      initialize = true; # initializes the repo, don't set if you want manual control
      passwordFile = config.age.secrets.restic_password.path;
      paths = ["/share/sftp/Android"];
      rcloneConfigFile = config.age.secrets.rclone_config.path;
      timerConfig = {
        OnCalendar = "03:00";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };

    quark_android = {
      user = "sftp";
      repository = "rclone:quark:restic";
      initialize = true; # initializes the repo, don't set if you want manual control
      passwordFile = config.age.secrets.restic_password.path;
      paths = ["/share/sftp/Android"];
      rcloneConfigFile = config.age.secrets.rclone_config.path;
      timerConfig = {
        OnCalendar = "03:00";
        Persistent = true;
        RandomizedDelaySec = "1h";
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

  services.duplicati = {
    enable = false;
    interface = "192.168.29.1";
  };

  net-name = {
    enable = true;
    inherit interfaces;
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
          pool = "192.168.30.50,192.168.30.150";
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
          pool = "::";
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
          pool = "192.168.29.50,192.168.29.150";
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
          pool = "::";
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
          pool = "192.168.28.50,192.168.28.150";
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
          pool = "::";
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
    "${interface.intern}" = {
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

      "30-ib" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "ib";
        };
      };
      "30-eth" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "eth";
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

      # Configure the bridge for its desired function
      "40-br0" = {
        matchConfig.Name = "br0";
        bridgeConfig = {};
        networkConfig = {
          # start a DHCP Client for IPv4 Addressing/Routing
          DHCP = "ipv4";
          # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
          IPv6AcceptRA = true;
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
        };
      };
    };
  };

  networking = {
    hostName = "homelab";
    domain = "lan";
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
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    # modesetting.enable = true;
    # forceFullCompositionPipeline = true;
    open = false;
    # powerManagement.enable = true;
  };
  hardware.nvidia-container-toolkit.enable = true; # for nvidia-docker

  hardware.graphics = {
    enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
