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
      "https://nixpkgs-wayland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
    ];
  };

  # This is the standard format for flake.nix. `inputs` are the dependencies of the flake,
  # Each item in `inputs` will be passed as a parameter to the `outputs` function after being pulled and built.
  inputs = {
    # There are many ways to reference flake inputs. The most widely used is github:owner/name/reference,
    # which represents the GitHub repository URL + branch/commit-id/tag.

    # Official NixOS package source, using nixos's stable branch by default
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs dependencies.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # community wayland nixpkgs
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";

    # generate iso/qcow2/docker/... image from nixos configuration
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dde-nixos = {
      url = "github:linuxdeepin/dde-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    # secrets management, lock with git commit at 2023/7/15
    agenix.url = "github:ryantm/agenix/0d8c5325fc81daf00532e3e26c6752f7bcde1143";

    # my private secrets, it's a private repository, you need to replace it with your own.
    # use ssh protocol to authenticate via ssh-agent/ssh-key, and shallow clone to save time
    mysecrets = {
      url = "git+ssh://git@github.com/pharra/agenix-secrets.git?shallow=1";
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
    nixpkgs-unstable,
    nix-darwin,
    home-manager,
    nixos-generators,
    dde-nixos,
    impermanence,
    ...
  }: let
    username = "wf";
    userfullname = "Feng Wang";
    useremail = "typechasing@gmail.com";

    x64_system = "x86_64-linux";
    allSystems = [x64_system];

    nixosSystem = import ./lib/nixosSystem.nix;

    dde-modules = dde-nixos.nixosModules.${x64_system};

    forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f system);
    legacyPackages = forAllSystems (system:
      import ./default.nix {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      });

    overlays = import ./overlay.nix;
  in {
    nixosConfigurations = let
      common-nixos-modules = [
        impermanence.nixosModules.impermanence
        dde-modules
      ];
      #desktop
      desktop_modules_gnome = {
        nixos-modules =
          [
            ./hosts/desktop
            ./modules/nixos/gnome.nix
          ]
          ++ common-nixos-modules;
        home-module = import ./home/desktop-gnome.nix;
      };

      # vm
      vm_modules_gnome = {
        nixos-modules =
          [
            ./hosts/vm
            ./modules/nixos/gnome.nix
          ]
          ++ common-nixos-modules;
        home-module = import ./home/desktop-gnome.nix;
      };

      # vm
      vm_modules_deepin = {
        nixos-modules =
          [
            ./hosts/vm
            ./modules/nixos/deepin.nix
          ]
          ++ common-nixos-modules;
        home-module = import ./home/desktop-deepin.nix;
      };

      # homelab
      homelab_modules_gnome = {
        nixos-modules =
          [
            ./hosts/homelab
            ./modules/nixos/gnome.nix
          ]
          ++ common-nixos-modules;
        home-module = import ./home/desktop-gnome.nix;
      };

      homelab_modules_deepin = {
        nixos-modules =
          [
            ./hosts/homelab
            ./modules/nixos/deepin.nix
          ]
          ++ common-nixos-modules;
        home-module = import ./home/desktop-deepin.nix;
      };

      system = x64_system;
      specialArgs =
        {
          inherit username userfullname useremail legacyPackages overlays;
          # use unstable branch for some packages to get the latest updates
          pkgs-unstable = import nixpkgs-unstable {
            system = x64_system; # refer the `system` parameter form outer scope recursively
            # To use chrome, we need to allow the installation of non-free software
            config.allowUnfree = true;
          };
        }
        // inputs;
      base_args = {
        inherit home-manager nixos-generators system specialArgs;
      };
      stable_args = base_args // {inherit nixpkgs;};
      unstable_args = base_args // {nixpkgs = nixpkgs-unstable;};
    in {
      # desktop with gnome
      desktop_gnome = nixosSystem (desktop_modules_gnome // stable_args);

      # vm with gnome
      vm_gnome = nixosSystem (vm_modules_gnome // stable_args);

      # vm with deepin
      vm_deepin = nixosSystem (vm_modules_deepin // stable_args);

      # homelab with gnome
      homelab_gnome = nixosSystem (homelab_modules_gnome // stable_args);

      homelab_deepin = nixosSystem (homelab_modules_deepin // stable_args);
    };

    # take system images for idols
    # https://github.com/nix-community/nixos-generators
    packages."${x64_system}" =
      # genAttrs returns an attribute set with the given keys and values(host => image).
      nixpkgs.lib.genAttrs [
        "desktop_gnome"
        "homelab_gnome"
        "vm_deepin"
        "vm_gnome"
      ] (
        host:
          self.nixosConfigurations.${host}.config.formats.vm
      )
      # // nixpkgs.lib.genAttrs [
      #   "vm_gnome"
      # ] (
      #   host:
      #     self.nixosConfigurations.${host}.config.formats.proxmox
      # )
      // nixpkgs.lib.filterAttrs (_: v: nixpkgs.lib.isDerivation v) legacyPackages.${x64_system};

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

    # format the nix code in this flake
    # alejandra is a nix formatter with a beautiful output
    formatter = nixpkgs.lib.genAttrs allSystems (
      system:
        nixpkgs.legacyPackages.${system}.alejandra
    );
  };
}
