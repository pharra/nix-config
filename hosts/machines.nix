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

    # 域名：azure/azure_arm 是"一份配置、多个实例"，实例之间只有域名不同，所以这里留空，
    # 实际值由每个实例自己提供（/root/domain）。确实要把某个实例钉死在这一份配置里时，才填这里。
    specialArgs = {
      domain = "";
    };
  }

  {
    name = "azure_arm";
    system = "aarch64-linux";
    desktop = "base";
    nixos-modules = [./azure];

    # 域名：azure/azure_arm 是"一份配置、多个实例"，实例之间只有域名不同，所以这里留空，
    # 实际值由每个实例自己提供（/root/domain）。确实要把某个实例钉死在这一份配置里时，才填这里。
    specialArgs = {
      domain = "";
    };
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
    desktop = "wm";
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
      inherit (inputs) nixpkgs;
      # 生成在 homelab 上运行的 zed guest 系统（NFS 启动）
      inherit mkZedGuest;
    };
  }
]
