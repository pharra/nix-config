# boot-over-nfs / boot-over-nvmf 共用的网络启动骨架。
# 两个模块里的 initrd 网络选项、wait-online、initrd 里的 systemd-networkd 接管、
# 阶段 2 的 networkd 接管、以及"等对端可达"的 oneshot 服务原本逐字相同（约 50 行），
# 抽到这里，避免以后只改一处。
#
# 注意：这是普通 .nix 文件（不是含 default.nix 的目录），所以不会被 importModules 当成模块自动导入。
{
  lib,
  pkgs,
}: rec {
  # 选项：initrd 里要拉起的网卡（第一个作为主接口）
  interfaceOption = defaultInterface:
    lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = defaultInterface;
      description = "Network interfaces to bring up in initrd (first entry is used as primary).";
    };

  # 选项：boot.kernelModules / boot.extraKernelParams
  bootOptions = {kernelModulesDefault}: {
    kernelModules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = kernelModulesDefault;
      description = "Extra initrd kernel modules needed to boot over the network.";
    };

    extraKernelParams = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional kernel parameters.";
    };
  };

  # 选项：network.dhcp
  networkOption = {
    dhcp = lib.mkOption {
      type = lib.types.str;
      default = "ipv4";
      description = "DHCP configuration (ipv4, ipv6, yes, no).";
    };
  };

  # 配置：initrd 里的 systemd-networkd（wait-online + 每个接口一个 network 文件）
  initrdNetwork = cfg: {
    enable = true;
    wait-online = {
      anyInterface = lib.mkForce false;
      timeout = 30;
    };
    networks = lib.listToAttrs (map (iface:
      lib.nameValuePair "40-${iface}-initrd" {
        matchConfig.Name = iface;
        networkConfig.DHCP = cfg.network.dhcp;
        linkConfig.RequiredForOnline = "routable";
      })
    cfg.interface);
  };

  # 配置：阶段 2 的 systemd-networkd（接管已经配好的接口）
  stage2Network = cfg:
    lib.listToAttrs (map (iface:
      lib.nameValuePair "40-${iface}" {
        matchConfig.Name = iface;
        networkConfig.KeepConfiguration = "yes";
      })
    cfg.interface);

  # 配置：initrd 里等对端可达的 oneshot 服务
  ensureNetwork = {peerAddress}: {
    enable = true;
    before = ["network-online.target"];
    wantedBy = ["network-online.target"];
    after = ["nss-lookup.target"];
    unitConfig.DefaultDependencies = "no";
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = 60;
      ExecStart = "${pkgs.bashInteractive}/bin/sh -c 'until ${pkgs.iputils}/bin/ping -c 1 ${peerAddress}; do ${pkgs.coreutils}/bin/sleep 1; done'";
    };
  };

  # 配置：initrd 里 systemd 的基本项（两个模块只有 initrdBin 多寡不同）
  initrdSystemd = {extraInitrdBin ? []}: {
    enable = true;
    emergencyAccess = true;
    initrdBin =
      [pkgs.iproute2 pkgs.pciutils pkgs.dnsutils pkgs.util-linux pkgs.coreutils pkgs.iputils]
      ++ extraInitrdBin;
  };
}
