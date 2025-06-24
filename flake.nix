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

    substituters = [
      # replace official cache with a mirror located in China
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-2305.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # nixos wsl
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
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
    };

    # my private secrets, it's a private repository, you need to replace it with your own.
    # use ssh protocol to authenticate via ssh-agent/ssh-key, and shallow clone to save time
    mysecrets = {
      url = "git+ssh://git@github.com/pharra/agenix-secrets.git?shallow=1";
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
  };

  # The `outputs` function will return all the build results of the flake.
  # A flake can have many use cases and different types of outputs,
  # parameters in `outputs` are defined in `inputs` and can be referenced by their names.
  # However, `self` is an exception, this special parameter points to the `outputs` itself (self-reference)
  # The `@` syntax here is used to alias the attribute set of the inputs's parameter, making it convenient to use inside the function.
  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nixpkgs-2305,
    nix-darwin,
    home-manager,
    impermanence,
    deploy-rs,
    mysecrets,
    nix-flatpak,
    plasma-manager,
    NixVirt,
    nixos-wsl,
    ...
  }: let
    username = "wf";
    userfullname = "Feng Wang";
    useremail = "typechasing@gmail.com";

    # azure vm config
    is_azure = true;

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
        plasma-manager.homeManagerModules.plasma-manager
      ]
      ++ (builtins.attrValues _home-modules);

    common-nixos-modules =
      [
        impermanence.nixosModules.impermanence
        nix-flatpak.nixosModules.nix-flatpak
        NixVirt.nixosModules.default
      ]
      ++ (builtins.attrValues modules);

    system = x64_system;

    commonSpecialArgs =
      {
        inherit username userfullname useremail legacyPackages overlays mysecrets deploy-rs home-modules NixVirt;
        # use unstable branch for some packages to get the latest updates
        pkgs-unstable = import nixpkgs-unstable {
          system = x64_system; # refer the `system` parameter form outer scope recursively
          # To use chrome, we need to allow the installation of non-free software
          config.allowUnfree = true;
        };

        pkgs-2305 = import nixpkgs-2305 {
          system = x64_system; # refer the `system` parameter form outer scope recursively
          # To use chrome, we need to allow the installation of non-free software
          config.allowUnfree = true;
        };
      }
      // inputs;
    base_args = {
      inherit home-manager system;
    };
    stable_args = base_args // {inherit nixpkgs;};
    unstable_args = base_args // {nixpkgs = nixpkgs-unstable;};

    hosts = let
      mkAzureHost = region: {
        name = "azure_${region}";
        hostname = "${region}.azure.int4byte.com";
        builds = ["base"];
        nixos-modules = [./hosts/azure];
        specialArgs = {
          inherit is_azure;
          domain = "${region}.azure.int4byte.com";
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
        builds = ["kde" "gnome" "cosmic" "deepin"];
        nixos-modules = [./hosts/dot];
      }

      # gs65
      {
        name = "gs65";
        builds = ["kde" "gnome" "cosmic" "deepin"];
        nixos-modules = [./hosts/gs65];
      }

      # minimal
      {
        name = "minimal";
        builds = ["kde" "gnome" "cosmic" "deepin" "base"];
        nixos-modules = [./hosts/minimal];
      }

      # zed
      {
        name = "zed";
        builds = ["kde" "gnome" "cosmic" "deepin"];
        hostname = "zed";
        nixos-modules = [./hosts/zed];
        specialArgs = {
          boot_from_network = false;
        };
      }

      # zed with netboot
      {
        name = "zed_netboot";
        builds = ["kde" "gnome" "cosmic" "deepin"];
        nixos-modules = [./hosts/zed];
        hostname = "zed.lan";
        specialArgs = {
          boot_from_network = true;
        };
      }

      # luris
      {
        name = "luris";
        builds = ["kde" "gnome" "cosmic" "deepin"];
        nixos-modules = [./hosts/luris];
        hostname = "luris.lan";
      }

      # dat
      {
        name = "dat";
        builds = ["kde" "gnome" "cosmic" "deepin"];
        nixos-modules = [./hosts/dat nixos-wsl.nixosModules.default];
        hostname = "dat.lan";
      }

      # homelab
      {
        name = "homelab";
        nixos-modules = [./hosts/homelab];
        builds = ["kde" "gnome" "cosmic" "deepin"];
        specialArgs = {
          netboot_args = {netboot_installer = self.nixosConfigurations."netboot_installer_base";};
        };
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
              else "${machine.name}.lan";
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

    devShells."${x64_system}".default = let
      pkgs = import nixpkgs {
        inherit x64_system;
        overlays = [
          (self: super: rec {
            nodejs = super.nodejs-18_x;
            pnpm = super.nodePackages.pnpm;
            yarn = super.yarn.override {inherit nodejs;};
          })
        ];
      };
    in
      pkgs.mkShell {
        # create an environment with nodejs-18_x, pnpm, and yarn
        packages = with pkgs; [
          cmake
          zsh
          gcc
          pkgsCross.mingwW64.buildPackages.gcc
          haskellPackages.nsis
          zlib
          binutils
          perl
          xz
          mtools
          cdrkit
          syslinux
        ];

        shellHook = ''
          # echo "node `${pkgs.nodejs}/bin/node --version`"
          exec zsh
        '';
      };

    inherit legacyPackages;

    # format the nix code in this flake
    # alejandra is a nix formatter with a beautiful output
    formatter = nixpkgs.lib.genAttrs allSystems (
      system:
        nixpkgs.legacyPackages.${system}.alejandra
    );
  };
}
