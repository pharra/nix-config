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

    ../../secrets/nixos.nix
    ./nixvirt
  ];

  services.pharra = {
    impermanence.enable = true;
    libvirt.enable = true;
    core-desktop.enable = true;
    user-group.enable = true;
    scripts.enable = true;
    virtualisation.enable = true;
  };

  # 使用 boot-over-nvmf 模块配置 ZFS
  services.nvmf-root = {
    enable = false;
    interface = interface.mlx5_0;

    # 禁用网络引导相关功能
    iscsi.enable = false;
    nvmf.enable = false;
    tmpfsRoot.enable = false;

    # ZFS 配置
    zfs = {
      poolName = "system";
      datasets = {
        root = {
          mountPoint = "/system";
          dataset = "";
          neededForBoot = true;
        };
        tmp = {
          mountPoint = "/tmp";
          dataset = "tmp";
          neededForBoot = true;
        };
        nix = {
          mountPoint = "/nix";
          dataset = "nix";
          neededForBoot = true;
        };
        var = {
          mountPoint = "/var";
          dataset = "var";
          neededForBoot = true;
        };
        "nix-var" = {
          mountPoint = "/nix/var";
          dataset = "nix/var";
          neededForBoot = true;
        };
        "nix-persistent" = {
          mountPoint = "/nix/persistent";
          dataset = "nix/persistent";
          neededForBoot = true;
        };
      };
    };

    boot.efiLabel = "boot";
  };

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
    wireless.enable = false; # Enables wireless support via wpa_supplicant.

    hostId = "88fcb8e9";

    networkmanager.enable = true;
    networkmanager.unmanaged = ["*,except:interface-name:wl*"];
  };

  net-name = {
    enable = true;
    inherit interfaces;
  };

  services.docker-netns = {
    enable = true;
    autoConfigureBridge = true;
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

      "40-${interface.mlx5_0}" = {
        matchConfig.Name = "${interface.mlx5_0}";
        networkConfig = {
          # start a DHCP Client for IPv4 Addressing/Routing
          DHCP = "ipv4";
          # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
          IPv6AcceptRA = true;
          Domains = ["mlx"];
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

  services.xserver.videoDrivers = ["amdgpu" "nvidia"]; # will install nvidia-vaapi-driver by default

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  hardware.nvidia = {
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;
    powerManagement.enable = true;
  };

  # ZFS 文件系统现在由 services.nvmf-root 模块管理

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
