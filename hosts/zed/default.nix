# 主力台式机：i5-13600KF + RTX 4090，日常与游戏用。
# 配置名：zed（desktop = kde）；从网络盘启动的是另一个配置 zed_net（宿主侧在 hosts/homelab）。
# 启用的功能：见本文件与 ./hardware-configuration.nix 里的 services.pharra / hardware.* enable 项；
# libvirt 客机定义在 ./nixvirt，CIFS 挂载在 ./cifs-mount.nix。
{
  config,
  pkgs,
  lib,
  ...
}:
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
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./cifs-mount.nix

    ../../secrets/nixos.nix
    ./nixvirt
  ];

  services.pharra = {
    nix-access-token.enable = true;
    preservation.enable = true;
    desktop.enable = true;
    virtualisation.enable = true;
    scripts.enable = true;
    # dsh web 常驻用户服务（http://127.0.0.1:3080）；wf 已开 linger，所以开机即启动
    deepseek-harness.enable = true;
    waydroid.enable = true;
    kmscon = {
      enable = true;
      # 4K 屏：kmscon 是"按字号在原生分辨率上渲染"，没有全局缩放，所以直接给大字号
      fontSize = 28;
    };
  };

  services.sunshine = lib.mkIf config.services.pharra.desktop.enable {
    enable = false;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  services.pharra.docker-netns =
    if config.services.pharra.openwrt.enable
    then {
      enable = config.virtualisation.docker.enable;
      autoConfigureBridge = false;
      dockerBridge = "br2";
      dockerGateway = "192.168.31.254";
      dockerHostIP = "192.168.31.2";
    }
    else {
      enable = config.virtualisation.docker.enable;
      autoConfigureBridge = true;
      dockerGateway = "192.168.31.254";
      dockerHostIP = "192.168.31.2";
    };

  services.mihomo.enable = true;

  # 使用 ZFS 模块配置基础支持
  services.zfs-config = {
    enable = true;
    hostId = "88fcb8e9";
    poolName = "system";
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  boot.loader.timeout = 1;

  networking = {
    hostName = "zed";

    networkmanager.unmanaged = ["*,except:interface-name:wl*"];
  };

  services.pharra.network-bridge = {
    enable = true;
    bridges = {
      br0 = {
        name = "br0";
        ports = [interface.net0];
        dhcp = true;
        ipv6AcceptRA = true;
        domains = ["lan"];
      };
    };
  };

  systemd.sleep.settings.Sleep = {
    AllowSuspend = false;
    AllowHibernation = false;
    AllowHybridSleep = false;
    AllowSuspendThenHibernate = false;
  };

  systemd.network = {
    enable = true;
    wait-online = {
      enable = false;
      anyInterface = true;
      timeout = 30;
    };
    networks = {
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
          UseRoutes = false;
        };
        ipv6AcceptRAConfig = {
          UseDNS = true;
          UseDomains = true;
        };
        linkConfig = {
          # or "routable" with IP addresses configured
          RequiredForOnline = "no";
        };
      };
    };
  };

  hardware.net-sriov = {
    enable = true;
    interfaces = [
      {
        number = 4;
        name = "mlx5_0";
      }
    ];
  };

  systemd.services = {
    ensure-network = {
      enable = false;
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

  # "nvidia" 是 nvidia 模块的开关（不是 Xorg 专用）；"amdgpu" 留给 APU，两套驱动并存。
  services.xserver.videoDrivers = ["nvidia" "amdgpu"];

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  hardware.nvidia = {
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    powerManagement.enable = true;
    nvidiaPersistenced = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
