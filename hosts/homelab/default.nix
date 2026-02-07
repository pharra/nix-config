{
  config,
  lib,
  pkgs,
  libs,
  mysecrets,
  username,
  mkZedGuest,
  nixpkgs,
  home-manager,
  ...
} @ args: let
  interface = {
    eth-to-bridge = "eno2";
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

  # Build zed guest system using function from flake
  zedGuestSystem = mkZedGuest {inherit nixpkgs home-manager;};
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../../secrets/nixos.nix

    ./nixvirt
  ];

  services.pharra = {
    libvirt.enable = true;
    core-desktop.enable = true;
    user-group.enable = true;
    impermanence.enable = true;
    spdk.enable = true;
    sftp-server.enable = true;
    caddy.enable = true;
    easytier.enable = true;
    scripts.enable = true;
    virtualisation.enable = true;
    azure-tools.enable = true;
    archlinux.enable = true;
  };

  # Enable iPXE NFS host to serve zed guest system
  services.ipxe-nfs-host = {
    enable = true;
    guests.zed = {
      system = zedGuestSystem;
      macs = ["9c:52:f8:8e:dd:d8" "58:47:ca:79:85:1c"];
    };
  };

  systemd.sleep.extraConfig = ''
    [Sleep]
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';

  # 使用 ZFS 模块配置基础支持
  services.zfs-config = {
    enable = true;
    hostId = "88fcb8e5";
    poolName = "system";
  };

  boot.zfs.package = pkgs.zfs_unstable;
  boot.zfs.extraPools = ["data"];
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

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

  services.restic.backups = {
    local_android = {
      user = "wf";
      repository = "/share/restic";
      initialize = true; # initializes the repo, don't set if you want manual control
      passwordFile = config.age.secrets.restic_password.path;
      paths = ["/share/sftp/Android"];
      timerConfig = {
        OnCalendar = "04:00";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };

  # systemd.timers."sync-115" = {
  #   wantedBy = ["timers.target"];
  #   timerConfig = {
  #     OnBootSec = "5m";
  #     OnUnitActiveSec = "6h";
  #     Unit = "sync-115.service";
  #   };
  # };

  # systemd.services."sync-115" = {
  #   script = ''
  #     set -eu
  #     ${pkgs.rclone}/bin/rclone --max-size 1G delete 115:/115open/云下载/share/media --config ${config.age.secrets.rclone_config.path}
  #     ${pkgs.rclone}/bin/rclone copy -Pv --min-size 1G 115:/115open/云下载/share/media /share/media --config ${config.age.secrets.rclone_config.path}
  #   '';
  #   serviceConfig = {
  #     Type = "oneshot";
  #     User = username;
  #   };
  # };

  # systemd.timers."sync-short" = {
  #   wantedBy = ["timers.target"];
  #   timerConfig = {
  #     OnBootSec = "5m";
  #     OnUnitActiveSec = "2h";
  #     Unit = "sync-short.service";
  #   };
  # };

  # systemd.services."sync-short" = {
  #   script = ''
  #     set -eu
  #     ${pkgs.rclone}/bin/rclone --max-size 100M delete 115:/115open/云下载/share/telegram --config ${config.age.secrets.rclone_config.path}
  #     ${pkgs.rclone}/bin/rclone copy -Pv --min-size 100M 115:/115open/云下载/share/telegram /share/telegram --config ${config.age.secrets.rclone_config.path}
  #   '';
  #   serviceConfig = {
  #     Type = "oneshot";
  #     User = username;
  #   };
  # };

  systemd.services = {
    tune-usb-autosuspend = {
      enable = false;
      description = "Disable USB autosuspend";
      wantedBy = ["multi-user.target"];
      serviceConfig = {Type = "oneshot";};
      unitConfig.RequiresMountsFor = "/sys";
      script = ''
        echo -1 > /sys/module/usbcore/parameters/autosuspend
      '';
    };
  };

  net-name = {
    enable = true;
    inherit interfaces;
  };

  services.openwrt.enable = false;

  services.nfs = {
    server = {
      enable = true;
      lockdPort = 4001;
      mountdPort = 4002;
      statdPort = 4000;
    };
    settings = {
      nfsd.udp = true;
      nfsd.rdma = true;
    };
  };

  services.docker-netns =
    if config.services.openwrt.enable
    then {
      enable = true;
      autoConfigureBridge = false;
      dockerBridge = "br2";
      dockerGateway = "192.168.31.254";
      dockerHostIP = "192.168.31.2";
    }
    else {
      enable = true;
      autoConfigureBridge = true;
      dockerGateway = "192.168.31.254";
      dockerHostIP = "192.168.31.2";
    };

  services.dhcpServer = {
    enable = true;
    networks = {
      eth = {
        name = "eth";
        interface = interface.eth;
        domain = "mlx";
        staticHosts = [
          {
            mac = "9c:52:f8:8e:dd:d8";
            ip = "192.168.29.2";
            hostname = "zed";
          }
        ];
        masquerade = "ipv4";
        ipv4 = {
          address = "192.168.29.1";
          netmask = "24";
          pool = "192.168.29.50,192.168.29.150";
        };
        ipv6 = {
          enable = false; # disable IPv6 for this network
          address = "fdd4:c514:7378:0::1";
          netmask = "64";
          pool = "::";
        };
      };

      intern = {
        name = "intern";
        interface = interface.intern;
        domain = "intern";
        # staticHosts = [
        #   {
        #     mac = "58:47:ca:79:85:1c";
        #     ip = "192.168.28.2";
        #     hostname = "zed";
        #   }
        # ];
        masquerade = "ipv4";
        ipv4 = {
          address = "192.168.28.1";
          netmask = "24";
          pool = "192.168.28.50,192.168.28.150";
        };
        ipv6 = {
          enable = false; # disable IPv6 for this network
          address = "fd00:0:28::1";
          pool = "::";
          netmask = "64";
        };
      };
    };
  };

  services.network-bridge = {
    enable = true;
    bridges = {
      br0 = {
        name = "br0";
        ports = ["eno1" "eno2"];
        dhcp = true;
        ipv6AcceptRA = true;
        domains = ["lan"];
      };
      br1 = {
        name = "br1";
        ports = [];
        configureNetwork = false;
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
    networkmanager.unmanaged = ["interface-name:*,except:interface-name:wl*"];
  };

  # for Nvidia GPU
  services.xserver.videoDrivers = ["nvidia"]; # will install nvidia-vaapi-driver by default
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.production;
    # modesetting.enable = true;
    # forceFullCompositionPipeline = true;
    open = true;
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
