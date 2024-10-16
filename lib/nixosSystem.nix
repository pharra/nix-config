{
  nixpkgs,
  home-manager,
  system,
  specialArgs,
  nixos-modules,
  home-module,
}: let
  username = specialArgs.username;
in
  nixpkgs.lib.nixosSystem {
    inherit system specialArgs;
    modules =
      nixos-modules
      ++ [
        {
          nixpkgs.overlays =
            [
              specialArgs.overlays
            ]
            ++ (builtins.attrValues specialArgs.legacyPackages."${system}".overlays);
        }

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.extraSpecialArgs = specialArgs;
          home-manager.users."${username}" = home-module;
          home-manager.sharedModules = specialArgs.home-modules;
        }
      ];
  }
