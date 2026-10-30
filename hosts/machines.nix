# 机器清单（显式表）：一行一台机器。加机器 = 建 hosts/<name>/ + 这里加一条。
# 每台机器会展开成 <name>_<build> 配置（build 见各自的 builds 列表，变体的含义见 lib/variants.nix）。
#
# 这个文件只放数据：name / system / hostname（部署地址）/ builds / nixos-modules / specialArgs。
# 装配逻辑在 lib/default.nix。
{
  lib,
  inputs,
  netboot,
  mkZedGuest,
}: [
  # azure 云主机（同一份配置，两个架构）
  {
    name = "azure";
    system = "x86_64-linux";
    builds = ["base"];
    nixos-modules = [./azure];
  }

  {
    name = "azure_arm";
    system = "aarch64-linux";
    builds = ["base"];
    nixos-modules = [./azure];
  }

  # Surface Book 2
  {
    name = "dot";
    system = "x86_64-linux";
    hostname = "192.168.254.240";
    builds = ["kde" "gnome" "cosmic" "wm"];
    nixos-modules = [./dot inputs.nixos-hardware.nixosModules.microsoft-surface-common];
  }

  # MSI GF65（hostname 是 nix65）
  {
    name = "gs65";
    system = "x86_64-linux";
    builds = ["kde" "gnome" "cosmic" "wm"];
    nixos-modules = [./gs65];
  }

  # 主力台式机
  {
    name = "zed";
    system = "x86_64-linux";
    builds = ["kde" "gnome" "cosmic" "wm" "denial"];
    nixos-modules = [
      ./zed
    ];
  }

  # 同一台 zed，但从 NVMF/iSCSI 网络盘启动（链路见 modules/boot/netboot/README.md）
  {
    name = "zed_net";
    system = "x86_64-linux";
    hostname = "zed";
    builds = ["kde" "gnome" "cosmic" "wm"];
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
    builds = ["kde" "gnome" "cosmic" "wm" "base"];
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
