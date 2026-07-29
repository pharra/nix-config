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
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
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
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # This is the standard format for flake.nix. `inputs` are the dependencies of the flake,
  # Each item in `inputs` will be passed as a parameter to the `outputs` function after being pulled and built.
  inputs = {
    # There are many ways to reference flake inputs. The most widely used is github:owner/name/reference,
    # which represents the GitHub repository URL + branch/commit-id/tag.

    # Official NixOS package source, using nixos's stable branch by default
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    nixpkgs.url = "github:salva09/nixpkgs?ref=cd8b0289be628b1f6330f7dcca7355866a27d78e";

    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/master";
      # url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # secrets management
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
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

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rime-config = {
      url = "github:Mintimate/oh-my-rime";
      flake = false;
    };

    nixinate = {
      url = "github:matthewcroughan/nixinate";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
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
    home-manager,
    impermanence,
    nix-flatpak,
    plasma-manager,
    NixVirt,
    nixos-hardware,
    sops-nix,
    rime-config,
    agenix,
    nixinate,
    dms-plugin-registry,
    noctalia,
    ...
  }: let
    username = "wf";
    allSystems = ["x86_64-linux" "aarch64-linux"];

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
        noctalia.homeModules.default
      ]
      ++ (builtins.attrValues _home-modules);

    common-nixos-modules =
      [
        impermanence.nixosModules.impermanence
        nix-flatpak.nixosModules.nix-flatpak
        NixVirt.nixosModules.default
        sops-nix.nixosModules.sops
        agenix.nixosModules.default
        dms-plugin-registry.nixosModules.default
        noctalia.nixosModules.default
        inputs.noctalia-greeter.nixosModules.default
      ]
      ++ (builtins.attrValues modules)
      ++ [
        {
          nixpkgs.overlays = [
            overlays
          ];
        }
      ];

    mysecrets = ./secrets/agenix;

    commonSpecialArgs = {
      inherit username mysecrets home-modules NixVirt rime-config agenix inputs;
    };
    base_args = {
      inherit home-manager;
    };
    stable_args = base_args // {inherit nixpkgs;};

    hosts = [
      # azure
      {
        name = "azure_arm";
        builds = ["base"];
        nixos-modules = [./hosts/azure];
        system = "aarch64-linux";
      }

      {
        name = "azure";
        builds = ["base"];
        nixos-modules = [./hosts/azure];
        system = "x86_64-linux";
      }

      # dot
      {
        name = "dot";
        builds = ["kde" "gnome" "cosmic" "wm"];
        hostname = "192.168.254.240";
        nixos-modules = [./hosts/dot nixos-hardware.nixosModules.microsoft-surface-common];
        system = "x86_64-linux";
      }

      # gs65
      {
        name = "gs65";
        builds = ["kde" "gnome" "cosmic" "wm"];
        nixos-modules = [./hosts/gs65];
        system = "x86_64-linux";
      }

      # zed
      {
        name = "zed";
        builds = ["kde" "gnome" "cosmic" "wm"];
        # hostname = "zed.local";
        nixos-modules = [
          ./hosts/zed
        ];
        system = "x86_64-linux";
      }

      # zed_netboot
      {
        name = "zed_net";
        builds = ["kde" "gnome" "cosmic" "wm"];
        hostname = "zed";
        system = "x86_64-linux";
        nixos-modules = [
          ./hosts/zed
          {
            services.zfs-config.poolName = nixpkgs.lib.mkForce "zed_net";

            services.nvmf-root = {
              enable = true;
              interface = ["mlx5_0"];
              nvmf = {
                enable = true;
                transport = "rdma";
                target = "nqn.2016-06.io.spdk:zed_net";
                address = "192.168.29.1";
                port = 4420;
              };
              iscsi = {
                enable = true;
                initiatorName = "iqn.2020-08.org.linux-iscsi.initiatorhost:zed_net";
                discoveryAddress = "192.168.29.1";
                targetName = "iqn.2016-06.io.spdk:zednetefi";
              };
              network = {
                dhcp = "ipv4";
              };
            };
            fileSystems."/boot/efi".device = nixpkgs.lib.mkForce "/dev/disk/by-label/zednetefi";
          }
        ];
      }

      # homelab
      {
        name = "homelab";
        nixos-modules = [
          ./hosts/homelab
        ];
        builds = ["kde" "gnome" "cosmic" "wm" "base"];
        system = "x86_64-linux";
        specialArgs = {
          inherit nixpkgs home-manager;
          # Pass a function to build zed guest system with NFS boot
          mkZedGuest = {
            nixpkgs,
            home-manager,
            ...
          }:
            nixosSystem {
              inherit nixpkgs home-manager;
              system = "x86_64-linux";
              specialArgs = commonSpecialArgs;
              nixos-modules =
                [./hosts/zed]
                ++ common-nixos-modules
                ++ [
                  (desktopModuleConfig "kde")
                  {
                    services.nfs-root = {
                      enable = true;
                      interface = ["mlx5_0"];
                      nfs = {
                        rootPath = "/system/zed/nix";
                        transport = "rdma";
                        multipathPeers = [
                          {
                            clientIp = "192.168.29.2";
                            serverIp = "192.168.29.1";
                          }
                          # {
                          #   clientIp = "192.168.254.2";
                          #   serverIp = "192.168.254.5";
                          # }
                        ];
                      };
                    };

                    services.nvmf-root = {
                      enable = true;
                      interface = ["mlx5_0"];
                      nvmf = {
                        enable = true;
                        transport = "rdma";
                        target = "nqn.2016-06.io.spdk:zed_net";
                        address = "192.168.29.1";
                        port = 4420;
                      };
                      iscsi = {
                        enable = false;
                      };
                      network = {
                        dhcp = "ipv4";
                      };
                    };

                    services.zfs-config.poolName = nixpkgs.lib.mkForce "zed_net";

                    fileSystems."/boot/efi".enable = nixpkgs.lib.mkForce false;
                  }
                ];
              home-module = import ./home/kde.nix;
            };
        };
      }
    ];

    generateNixosConfigurations = f: (machines: builtins.map (machine: f machine) machines);

    # Generate desktop environment module configuration based on build type
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
            variant = "dms";
            compositor = "niri";
          };
        }
        else {
          base.enable = true;
        }; # base build - no desktop environment
    };

    machinesNixosConfigurations = builtins.listToAttrs (builtins.concatLists (generateNixosConfigurations (machine: let
    in
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
            home-module = import ./home/${build}.nix;
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
    nixosConfigurations = machinesNixosConfigurations;
    apps = forAllSystems (system: (nixinate.nixinate.${system} self).nixinate);

    inherit legacyPackages;

    packages = {
      "aarch64-linux" = {
        azure-arm = machinesNixosConfigurations.azure_arm_base.config.system.build.azureImage;
      };
      "x86_64-linux" = {
        azure-x64 = machinesNixosConfigurations.azure_base.config.system.build.azureImage;
      };
    };

    # format the nix code in this flake
    # alejandra is a nix formatter with a beautiful output
    formatter = nixpkgs.lib.genAttrs allSystems (
      system:
        nixpkgs.legacyPackages.${system}.alejandra
    );
  };
}
