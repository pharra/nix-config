{
  description = "NixOS & macOS configuration of Ryan Yin";

  ##################################################################################################################
  #
  # Want to know Nix in details? Looking for a beginner-friendly tutorial?
  # Check out https://github.com/ryan4yin/nixos-and-flakes-book !
  #
  ##################################################################################################################

  # the nixConfig here only affects the flake itself, not the system configuration!
  nixConfig = {
    experimental-features = ["nix-command" "flakes"];

    post-build-hook = ./scripts/upload-to-cache.sh;

    substituters = [
      # replace official cache with a mirror located in China
      "https://attic.int4byte.org:8443/nix"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];

    trusted-public-keys = [
      "nix:TIuZSOR7smXF/Jz1UKnvY5TW+NvklDypmDEg57QYU08="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];

    # nix community's cache server
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # This is the standard format for flake.nix. `inputs` are the dependencies of the flake,
  # Each item in `inputs` will be passed as a parameter to the `outputs` function after being pulled and built.
  inputs = {
    # There are many ways to reference flake inputs. The most widely used is github:owner/name/reference,
    # which represents the GitHub repository URL + branch/commit-id/tag.

    # Official NixOS package source, using nixos's stable branch by default
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:FriedrichAltheide/nixpkgs/add-depmod-overrides";

    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/master";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs dependencies.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    # secrets management
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    mysecrets = {
      url = "github:pharra/agenix-secrets";
      flake = false;
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak = {
      url = "github:gmodena/nix-flatpak";
    };

    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    NixVirt = {
      url = "github:AshleyYakeley/NixVirt";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rime-config = {
      url = "github:Mintimate/oh-my-rime";
      flake = false;
    };
  };

  # The `outputs` function will return all the build results of the flake.
  # A flake can have many use cases and different types of outputs,
  # parameters in `outputs` are defined in `inputs` and can be referenced by their names.
  # However, `self` is an exception, this special parameter points to the `outputs` itself (self-reference)
  # The `@` syntax here is used to alias the attribute set of the inputs's parameter, making it convenient to use inside the function.
  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    impermanence,
    deploy-rs,
    mysecrets,
    nix-flatpak,
    plasma-manager,
    NixVirt,
    nixos-hardware,
    sops-nix,
    rime-config,
    agenix,
    ...
  }: let
    username = "wf";
    userfullname = "Feng Wang";
    useremail = "typechasing@gmail.com";

    x64_system = "x86_64-linux";
    allSystems = [x64_system];

    nixosSystem = import ./lib/nixosSystem.nix;

    forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f system);
    legacyPackages = forAllSystems (system:
      import ./default.nix {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      });

    overlays = import ./overlay.nix;

    modules = import ./modules;
    _home-modules = import ./home-modules;
    home-modules =
      [
        plasma-manager.homeModules.plasma-manager
      ]
      ++ (builtins.attrValues _home-modules);

    common-nixos-modules =
      [
        impermanence.nixosModules.impermanence
        nix-flatpak.nixosModules.nix-flatpak
        NixVirt.nixosModules.default
        sops-nix.nixosModules.sops
      ]
      ++ (builtins.attrValues modules)
      ++ [
        {
          nixpkgs.overlays = [
            overlays
          ];
        }
      ];

    system = x64_system;

    commonSpecialArgs = {
      inherit username userfullname useremail mysecrets deploy-rs home-modules NixVirt rime-config agenix;
    };
    base_args = {
      inherit home-manager system;
    };
    stable_args = base_args // {inherit nixpkgs;};

    hosts = let
      mkAzureHost = region: {
        name = "azure_${region}";
        hostname = "${region}.azure.int4byte.org";
        builds = ["base"];
        nixos-modules = [./hosts/azure];
        specialArgs = {
          domain = "${region}.azure.int4byte.org";
        };
      };
    in [
      # azure
      (mkAzureHost "hk")
      (mkAzureHost "jp")
      (mkAzureHost "us")
      (mkAzureHost "sg")

      # installer
      {
        name = "netboot_installer";
        builds = ["base"];
        nixos-modules = [./hosts/installer/netboot.nix];
      }

      # dot
      {
        name = "dot";
        builds = ["kde" "gnome" "cosmic"];
        hostname = "192.168.254.240";
        nixos-modules = [./hosts/dot nixos-hardware.nixosModules.microsoft-surface-common];
      }

      # gs65
      {
        name = "gs65";
        builds = ["kde" "gnome" "cosmic"];
        nixos-modules = [./hosts/gs65];
      }

      # minimal
      {
        name = "minimal";
        builds = ["base"];
        nixos-modules = [./hosts/minimal];
      }

      # zed
      {
        name = "zed";
        builds = ["kde" "gnome" "cosmic"];
        hostname = "zed.mlx";
        nixos-modules = [./hosts/zed];
        specialArgs = {
          boot_from_network = false;
        };
      }

      # zed netboot
      {
        name = "zed_netboot";
        builds = ["kde" "gnome" "cosmic"];
        hostname = "zed";
        nixos-modules = [./hosts/zed];
        specialArgs = {
          boot_from_network = true;
        };
      }

      # homelab
      {
        name = "homelab";
        nixos-modules = [./hosts/homelab];
        builds = ["kde" "gnome" "cosmic" "base"];
      }
    ];

    generateNixosConfigurations = f: (machines: builtins.map (machine: f machine) machines);

    machinesNixosConfigurations = builtins.listToAttrs (builtins.concatLists (generateNixosConfigurations (machine: let
    in
      builtins.map (build: {
        name = "${machine.name}_${build}";
        value = nixosSystem ({
            nixos-modules = machine.nixos-modules ++ common-nixos-modules ++ [./nixos/${build}.nix];
            home-module = import ./home/${build}.nix;
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
    nixosConfigurations = machinesNixosConfigurations;

    deploy = let
      deployConfigurations = builtins.listToAttrs (builtins.concatLists (generateNixosConfigurations (machine: let
      in
        builtins.map (build: {
          name = "${machine.name}_${build}";
          value = {
            hostname =
              if builtins.hasAttr "hostname" machine
              then machine.hostname
              else "${machine.name}";
            profiles.system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."${machine.name}_${build}";
            };
          };
        })
        machine.builds)
      hosts));
    in {
      sshUser = "wf";
      user = "root";
      # sshOpts = ["-p" "2222"];
      autoRollback = false;

      magicRollback = false;
      nodes = deployConfigurations;
    };

    inherit legacyPackages;

    checks = nixpkgs.lib.genAttrs ["x86_64-linux"] (
      system: let
        inherit (nixpkgs) lib;
        filteredConfigs =
          lib.filterAttrs
          (name: cfg: lib.elem name ["zed_kde" "homelab_kde"] && cfg.pkgs.system == system)
          self.nixosConfigurations;
        nixosMachines =
          lib.mapAttrs' (
            name: config: lib.nameValuePair "nixos-${name}" config.config.system.build.toplevel
          )
          filteredConfigs;
      in
        nixosMachines
    );

    packages = nixpkgs.lib.genAttrs allSystems (
      # system: {azure-image = machinesNixosConfigurations.azure_jp_base.config.system.build.azureImage;}
      system: let
        inherit (nixpkgs) lib;
        filteredConfigs =
          lib.filterAttrs
          (name: cfg: cfg.pkgs.system == system)
          self.nixosConfigurations;
        nixosMachines =
          lib.mapAttrs' (
            name: config: lib.nameValuePair name config.config.system.build.toplevel
          )
          filteredConfigs;
      in
        nixosMachines
    );

    # format the nix code in this flake
    # alejandra is a nix formatter with a beautiful output
    formatter = nixpkgs.lib.genAttrs allSystems (
      system:
        nixpkgs.legacyPackages.${system}.alejandra
    );
  };
}
