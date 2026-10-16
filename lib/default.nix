# 仓库内部上下文：把 flake inputs 整理成生成 nixosConfigurations 所需的一切。
# 约定：flake.nix 只放 inputs 与输出装配；构建逻辑在这里；host 数据在 hosts/registry.nix；
#      build 变体在 lib/variants.nix；模块目录用 lib/importModules.nix 自动发现。
{
  inputs,
  username,
}: let
  inherit (inputs) nixpkgs home-manager NixVirt agenix impermanence nix-flatpak sops-nix dms-plugin-registry;
  inherit (nixpkgs) lib;

  nixosSystem = import ./nixosSystem.nix;
  importModules = import ./importModules.nix;
  netboot = import ./netboot.nix {inherit lib;};
  variants = import ./variants.nix {inherit lib;};

  # 模块目录自动发现：新增 modules/<name>/default.nix 即自动生效，不用改注册表
  modules = importModules {dir = ../modules;};
  home-modules = builtins.attrValues (importModules {dir = ../home-modules;});

  overlays = import ../overlay.nix;
  overlay = import ../overlays;

  common-nixos-modules =
    [
      impermanence.nixosModules.impermanence
      nix-flatpak.nixosModules.nix-flatpak
      NixVirt.nixosModules.default
      sops-nix.nixosModules.sops
      agenix.nixosModules.default
      dms-plugin-registry.nixosModules.default
      inputs.denial-nixos.nixosModules.default
      inputs.waydroid-nvidia-nix.nixosModules.waydroid-nvidia
      {
        services.waydroid-nvidia.package = inputs.waydroid-nvidia-nix.packages.x86_64-linux.waydroid-nvidia-full;
      }
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

  mysecrets = ../secrets/agenix;

  commonSpecialArgs = {
    inherit username mysecrets home-modules NixVirt agenix inputs;
  };

  mkZedGuest = import ./mkZedGuest.nix {
    inherit nixosSystem common-nixos-modules commonSpecialArgs netboot variants username;
  };

  hosts = import ../hosts/registry.nix {inherit lib inputs netboot mkZedGuest;};

  base_args = {inherit home-manager;};
  stable_args = base_args // {inherit nixpkgs;};

  nixosConfigurations = builtins.listToAttrs (builtins.concatLists (builtins.map (machine:
    builtins.map (build: {
      name = "${machine.name}_${build}";
      value = nixosSystem ({
          nixos-modules =
            machine.nixos-modules
            ++ common-nixos-modules
            ++ [
              (variants.nixosModule build)
              {
                _module.args.nixinate = {
                  host =
                    if builtins.hasAttr "hostname" machine
                    then machine.hostname
                    else machine.name;
                  sshUser = username;
                  buildOn = "local"; # valid args are "local" or "remote"
                  substituteOnTarget = true; # if buildOn is "local" then it will substitute on the target, "-s"
                };
              }
            ];
          home-module = variants.mkHomeModule username build;
          system = machine.system;
        }
        // stable_args
        // {
          specialArgs = let
            machineSpecialArgs =
              if builtins.hasAttr "specialArgs" machine
              then machine.specialArgs
              else {};
          in
            commonSpecialArgs // machineSpecialArgs;
        });
    })
    machine.builds)
  hosts));
in {
  inherit nixosConfigurations;
}
