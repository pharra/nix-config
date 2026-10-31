# 机器清单（显式表）：一行一台机器，桌面是一个值（desktop）。
# 加机器 = 建 hosts/<name>/ + 这里加一条；换桌面 = 改这里的 desktop 一行。
#
# 这个文件只放数据：name / system / desktop / hostname（部署地址）/ nixos-modules / specialArgs。
# 装配逻辑在 lib/default.nix；desktop 的可选值与含义见 lib/variants.nix。
{
  inputs,
  netboot,
  mkZedGuest,
}: [
  # azure 云主机（同一份配置，两个架构）
  {
    name = "azure";
    system = "x86_64-linux";
    desktop = "base";
    nixos-modules = [./azure];

    # 这台机器的域名（每个 azure 主机一个）。填上之后就不需要手工文件 /root/domain 了，
    # 机制见 hosts/azure/server/default.nix（留空则回退到 /root/domain）。
    specialArgs = {
      domain = "";
    };
  }

  {
    name = "azure_arm";
    system = "aarch64-linux";
    desktop = "base";
    nixos-modules = [./azure];

    # 这台机器的域名（每个 azure 主机一个）。填上之后就不需要手工文件 /root/domain 了，
    # 机制见 hosts/azure/server/default.nix（留空则回退到 /root/domain）。
    specialArgs = {
      domain = "";
    };
  }

  # Surface Book 2
  {
    name = "dot";
    system = "x86_64-linux";
    desktop = "wm";
    hostname = "192.168.254.240";
    nixos-modules = [./dot inputs.nixos-hardware.nixosModules.microsoft-surface-common];
  }

  # MSI GF65（hostname 是 nix65）
  {
    name = "gs65";
    system = "x86_64-linux";
    desktop = "kde";
    nixos-modules = [./gs65];
  }

  # 主力台式机
  {
    name = "zed";
    system = "x86_64-linux";
    desktop = "kde";
    nixos-modules = [
      ./zed
    ];
  }

  # 同一台 zed，但从 NVMF/iSCSI 网络盘启动（链路见 modules/boot/netboot/README.md）
  {
    name = "zed_net";
    system = "x86_64-linux";
    desktop = "kde";
    hostname = "zed";
    nixos-modules = [
      ./zed
      (netboot.nvmfRoot {iscsi = netboot.iscsiBoot;})
      netboot.efiFromIscsi
    ];
  }

  # 服务器
  {
    name = "homelab";
    system = "x86_64-linux";
    desktop = "base";
    nixos-modules = [
      ./homelab
    ];
    specialArgs = {
      inherit (inputs) nixpkgs home-manager;
      # 生成在 homelab 上运行的 zed guest 系统（NFS 启动）
      inherit mkZedGuest;
    };
  }
]
