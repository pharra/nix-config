# 仓库内部上下文：把 flake inputs 整理成生成 nixosConfigurations 所需的一切。
# 约定：flake.nix 只放 inputs 与输出装配；构建逻辑在这里；host 数据在 hosts/registry.nix。
{
  inputs,
  username,
}: let
  inherit (inputs) nixpkgs home-manager NixVirt agenix impermanence nix-flatpak sops-nix dms-plugin-registry;
  inherit (nixpkgs) lib;

  nixosSystem = import ./nixosSystem.nix;

  modules = import ../modules;
  home-modules = builtins.attrValues (import ../home-modules);
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

  # build 变体 -> NixOS 侧桌面模块配置
  desktopModuleConfig = build: {
    services.pharra =
      if build == "kde"
      then {kde.enable = true;}
      else if build == "gnome"
      then {gnome.enable = true;}
      else if build == "cosmic"
      then {cosmic.enable = true;}
      else if build == "wm"
      then {
        desktopShell = {
          enable = true;
          variant = "noctalia";
        };
      }
      else if build == "denial"
      then {denial.enable = true;}
      else {
        base.enable = true;
      }; # base build - no desktop environment
  };

  mkZedGuest = import ./mkZedGuest.nix {
    inherit nixosSystem common-nixos-modules commonSpecialArgs desktopModuleConfig;
    home-module = import ../home/kde.nix;
  };

  hosts = import ../hosts/registry.nix {inherit lib inputs mkZedGuest;};

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
              (desktopModuleConfig build)
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
          home-module = import ../home/${build}.nix;
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
    }) machine.builds)
    hosts));
in {
  inherit nixosConfigurations;
}
