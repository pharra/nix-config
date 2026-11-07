{
  nixpkgs,
  system,
  specialArgs,
  nixos-modules,
}: let
  inherit (specialArgs) username;
in
  nixpkgs.lib.nixosSystem {
    inherit system specialArgs;
    modules =
      nixos-modules
      ++ [
        {
          # hjem 的基础用户配置；各模块通过 hjem.extraModules 继续补充
          hjem.users.${username} = {
            enable = true;
            user = username;
            directory = "/home/${username}";
            # hjem 的文件链接语义：目标存在也覆盖
            clobberFiles = true;
          };
        }
      ];
  }
