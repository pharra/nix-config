# 仓库内部上下文：把 flake inputs 整理成生成 nixosConfigurations 所需的一切。
# 约定：flake.nix 只放 inputs 与输出装配；构建逻辑在这里；host 数据在 hosts/machines.nix；
#      build 变体在 lib/variants.nix；模块目录用 显式清单。
{
  inputs,
  username,
}: let
  inherit (inputs) nixpkgs hjem NixVirt impermanence nix-flatpak sops-nix dms-plugin-registry;
  inherit (nixpkgs) lib;

  nixosSystem = import ./nixosSystem.nix;
  # 模块清单：显式写在各目录的 default.nix 里（不再用目录自动发现）
  netboot = import ../modules/boot/netboot/netboot.nix {inherit lib;};
  variants = import ./variants.nix {inherit lib;};

  # 模块清单（显式）：modules/default.nix；variant 的用户配置现在也在 modules/ 里
  modules = import ../modules;

  overlays = import ../overlay.nix;
  overlay = import ../overlays;

  # 全局 NixOS 模块列表：这里的模块会在**每个**配置里求值（全有或全无）。
  #
  # 放什么：只放"所有机器都必须有它的选项"的基础设施（秘密、持久化、虚拟化、flatpak 这类）。
  # 不放什么：只在部分机器上用的功能模块 —— 那种应该在 host 里写
  #          imports = [inputs.<名字>.nixosModules.default];
  #          （specialArgs 里已经有 inputs，见下面的 commonSpecialArgs）
  #
  # 加进来之前务必确认它的选项路径不与 nixpkgs 冲突：boot.iscsi-initiator 就撞过车，
  # 本地副本只好改叫 boot.iscsi-root（见 modules/boot/iscsi-root/default.nix 的注释）。
  # 完整流程见 docs/EXTENDING.md 的「加一个上游（GitHub）flake 模块」。
  common-nixos-modules =
    [
      impermanence.nixosModules.impermanence
      nix-flatpak.nixosModules.nix-flatpak
      NixVirt.nixosModules.default
      sops-nix.nixosModules.sops
      hjem.nixosModules.default
      dms-plugin-registry.nixosModules.default
      inputs.denial.nixosModules.default
      inputs.waydroid-nvidia-nix.nixosModules.waydroid-nvidia
      {
        services.waydroid-nvidia.package = inputs.waydroid-nvidia-nix.packages.x86_64-linux.waydroid-nvidia-full;
      }
      inputs.babry.nixosModules.default
    ]
    ++ (builtins.attrValues modules)
    ++ [
      {
        nixpkgs.overlays =
          [
            overlays
            inputs.niri-glass.overlays.default
            inputs.nix-cachyos-kernel.overlays.default
          ]
          ++ builtins.attrValues overlay;
      }
    ];

  commonSpecialArgs = {
    inherit username NixVirt inputs;
  };

  mkZedGuest = import ../modules/boot/netboot/mkZedGuest.nix {
    inherit nixosSystem common-nixos-modules commonSpecialArgs netboot variants;
  };

  machines = import ../hosts/machines.nix {inherit inputs netboot mkZedGuest;};

  stable_args = {inherit nixpkgs;};

  # 一台机器一个配置：桌面是 hosts/machines.nix 里的一个值（desktop），不再是配置名后缀
  mkMachine = machine:
    nixosSystem ({
        nixos-modules =
          machine.nixos-modules
          ++ common-nixos-modules
          ++ [
            (variants.nixosModule machine.desktop)
            {
              _module.args.nixinate = {
                host = machine.hostname or machine.name;
                sshUser = username;
                buildOn = "local"; # valid args are "local" or "remote"
                substituteOnTarget = true; # if buildOn is "local" then it will substitute on the target, "-s"
              };
            }
          ];
        inherit (machine) system;
      }
      // stable_args
      // {
        specialArgs = commonSpecialArgs // (machine.specialArgs or {});
      });

  nixosConfigurations = builtins.listToAttrs (map (machine: {
      inherit (machine) name;
      value = mkMachine machine;
    })
    machines);
in {
  inherit nixosConfigurations;
}
