# host 清单：每个条目展开成一组 <name>_<build> 配置（逻辑见 lib/default.nix）。
# 这个文件只放数据：name / builds / system / hostname / nixos-modules / specialArgs。
{
  lib,
  inputs,
  netboot,
  mkZedGuest,
}: [
  # azure
  {
    name = "azure_arm";
    builds = ["base"];
    nixos-modules = [./azure];
    system = "aarch64-linux";
  }

  {
    name = "azure";
    # CI 里编译 x86_64 的完整系统（azure_arm 同目录，但不重复编译）
    ci = {builds = ["base"];};
    builds = ["base"];
    nixos-modules = [./azure];
    system = "x86_64-linux";
  }

  # dot
  {
    name = "dot";
    # CI 里只编译 wm 变体的内核（便宜的冒烟测试）
    ci = {
      builds = ["wm"];
      target = "kernel";
    };
    builds = ["kde" "gnome" "cosmic" "wm"];
    hostname = "192.168.254.240";
    nixos-modules = [./dot inputs.nixos-hardware.nixosModules.microsoft-surface-common];
    system = "x86_64-linux";
  }

  # gs65
  {
    name = "gs65";
    builds = ["kde" "gnome" "cosmic" "wm"];
    nixos-modules = [./gs65];
    system = "x86_64-linux";
  }

  # zed
  {
    name = "zed";
    builds = ["kde" "gnome" "cosmic" "wm" "denial"];
    # hostname = "zed.local";
    nixos-modules = [
      ./zed
    ];
    system = "x86_64-linux";
  }

  # zed_netboot
  {
    name = "zed_net";
    ci = {builds = ["wm"];};
    builds = ["kde" "gnome" "cosmic" "wm"];
    hostname = "zed";
    system = "x86_64-linux";
    nixos-modules = [
      ./zed
      (netboot.nvmfRoot {iscsi = netboot.iscsiBoot;})
      netboot.efiFromIscsi
    ];
  }

  # homelab
  {
    name = "homelab";
    ci = {builds = ["base"];};
    nixos-modules = [
      ./homelab
    ];
    builds = ["kde" "gnome" "cosmic" "wm" "base"];
    system = "x86_64-linux";
    specialArgs = {
      inherit (inputs) nixpkgs home-manager;
      # 生成在 homelab 上运行的 zed guest 系统（NFS 启动）
      inherit mkZedGuest;
    };
  }
]
