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
    nixpkgs-2305.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/master";
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
      url = "github:gmodena/nix-flatpak/?ref=v0.2.0";
    };

    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
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
    nixos-generators,
    impermanence,
    deploy-rs,
    mysecrets,
    nix-flatpak,
    plasma-manager,
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
    home-modules = import ./home-modules;
    plasma-manager-module = plasma-manager.homeManagerModules.plasma-manager;
  in {
    nixosConfigurations = let
      common-nixos-modules =
        [
          impermanence.nixosModules.impermanence
          nix-flatpak.nixosModules.nix-flatpak
        ]
        ++ (builtins.attrValues modules);

      #desktop
      desktop_modules_gnome = {
        nixos-modules =
          [
            ./hosts/desktop
            ./nixos/gnome.nix
          ]
          ++ common-nixos-modules;
        home-module = import ./home/desktop-gnome.nix;
      };

      desktop_modules_kde = {
        nixos-modules =
          [
            ./hosts/desktop
            ./nixos/kde.nix
          ]
          ++ common-nixos-modules;
        home-module = import ./home/desktop-kde.nix;
      };

      # gs65
      gs65_modules_gnome = {
        nixos-modules =
          [
            ./hosts/gs65
            ./nixos/gnome.nix
          ]
          ++ common-nixos-modules;
        home-module = import ./home/desktop-gnome.nix;
      };

      # vm
      vm_modules_gnome = {
        nixos-modules =
          [
            ./hosts/vm
            ./nixos/gnome.nix
          ]
          ++ common-nixos-modules;
        home-module = import ./home/desktop-gnome.nix;
      };

      # vm
      vm_modules_deepin = {
        nixos-modules =
          [
            ./hosts/vm
            ./nixos/deepin.nix
          ]
          ++ common-nixos-modules;
        home-module = import ./home/desktop-deepin.nix;
      };

      # netboot installer
      installer_modules_base = {
        nixos-modules =
          [
            ./hosts/installer/netboot.nix
          ]
          ++ common-nixos-modules;
        home-module = import ./home/base.nix;
      };

      # minimal
      minimal_modules_base = {
        nixos-modules =
          [
            ./hosts/minimal
          ]
          ++ common-nixos-modules;
        home-module = import ./home/base.nix;
      };

      # homelab
      homelab_modules_gnome = {
        nixos-modules =
          [
            ./hosts/homelab
            ./nixos/gnome.nix
          ]
          ++ common-nixos-modules;
        home-module = import ./home/desktop-gnome.nix;
      };

      homelab_modules_deepin = {
        nixos-modules =
          [
            ./hosts/homelab
            ./nixos/deepin.nix
          ]
          ++ common-nixos-modules;
        home-module = import ./home/desktop-deepin.nix;
      };

      homelab_modules_kde = {
        nixos-modules =
          [
            ./hosts/homelab
            ./nixos/kde.nix
          ]
          ++ common-nixos-modules;
        home-module = import ./home/desktop-kde.nix;
      };

      # azure
      azure_modules_base = {
        nixos-modules =
          [
            ./hosts/azure
          ]
          ++ common-nixos-modules;
        home-module = import ./home/base.nix;
      };

      system = x64_system;
      _specialArgs =
        {
          inherit username userfullname useremail legacyPackages overlays mysecrets deploy-rs home-modules plasma-manager-module;
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
        inherit home-manager nixos-generators system;
      };
      stable_args = base_args // {inherit nixpkgs;};
      unstable_args = base_args // {nixpkgs = nixpkgs-unstable;};

      # desktop with gnome
      desktop_gnome = nixosSystem (desktop_modules_gnome // stable_args // {specialArgs = _specialArgs;});

      # desktop with kde
      desktop_kde = nixosSystem (desktop_modules_kde // stable_args // {specialArgs = _specialArgs;});

      # gs65 with gnome
      gs65_gnome = nixosSystem (gs65_modules_gnome // stable_args // {specialArgs = _specialArgs;});

      # vm with gnome
      vm_gnome = nixosSystem (vm_modules_gnome // stable_args // {specialArgs = _specialArgs;});

      # netboot installer with base
      netboot_installer = nixosSystem (installer_modules_base // stable_args // {specialArgs = _specialArgs;});

      # minimal with base
      minimal_base = nixosSystem (minimal_modules_base // stable_args // {specialArgs = _specialArgs;});

      # azure vms
      azure_hk = nixosSystem (azure_modules_base
        // stable_args
        // {
          specialArgs =
            _specialArgs
            // {
              inherit is_azure;
              domain = "hk.azure.int4byte.com";
            };
        });

      azure_sg = nixosSystem (azure_modules_base
        // stable_args
        // {
          specialArgs =
            _specialArgs
            // {
              inherit is_azure;
              domain = "sg.azure.int4byte.com";
            };
        });

      azure_us = nixosSystem (azure_modules_base
        // stable_args
        // {
          specialArgs =
            _specialArgs
            // {
              inherit is_azure;
              domain = "us.azure.int4byte.com";
            };
        });

      azure_jp = nixosSystem (azure_modules_base
        // stable_args
        // {
          specialArgs =
            _specialArgs
            // {
              inherit is_azure;
              domain = "jp.azure.int4byte.com";
            };
        });

      netboot_args = {inherit desktop_gnome netboot_installer;};

      homelab_gnome_args = homelab_modules_gnome // stable_args // {specialArgs = _specialArgs // {inherit netboot_args;};};

      homelab_deepin_args = homelab_modules_deepin // stable_args // {specialArgs = _specialArgs // {inherit netboot_args;};};

      homelab_kde_args = homelab_modules_kde // stable_args // {specialArgs = _specialArgs // {inherit netboot_args;};};
    in {
      # desktop with gnome
      inherit desktop_gnome;

      # desktop with kde
      inherit desktop_kde;

      # minimal with base
      inherit minimal_base;

      # gs65 with gnome
      inherit gs65_gnome;

      # vm with gnome
      inherit vm_gnome;

      # azure vms
      inherit azure_hk azure_sg azure_us azure_jp;

      # homelab with gnome
      homelab_gnome = nixosSystem homelab_gnome_args;

      homelab_deepin = nixosSystem homelab_deepin_args;

      homelab_kde = nixosSystem homelab_kde_args;
    };

    deploy = {
      sshUser = "wf";
      user = "root";
      # sshOpts = ["-p" "2222"];
      autoRollback = false;

      magicRollback = false;
      nodes = {
        "azure_hk" = {
          hostname = "hk.azure.int4byte.com";
          profiles.system = {
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."azure_hk";
          };
        };
        "azure_sg" = {
          hostname = "sg.azure.int4byte.com";
          profiles.system = {
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."azure_sg";
          };
        };
        "azure_us" = {
          hostname = "us.azure.int4byte.com";
          profiles.system = {
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."azure_us";
          };
        };
        "azure_jp" = {
          hostname = "jp.azure.int4byte.com";
          profiles.system = {
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."azure_jp";
          };
        };

        "gs65_gnome" = {
          hostname = "192.168.31.156";
          profiles.system = {
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."gs65_gnome";
          };
        };

        "desktop_gnome" = {
          hostname = "192.168.29.127";
          profiles.system = {
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."desktop_gnome";
          };
        };

        "desktop_kde" = {
          hostname = "192.168.29.127";
          profiles.system = {
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."desktop_kde";
          };
        };
      };
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
        "gs65_gnome"
      ] (
        host:
          self.nixosConfigurations.${host}.config.formats.iso
      )
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
