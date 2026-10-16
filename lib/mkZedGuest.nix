# 在 homelab 上运行的 zed 网络启动 guest 系统（NFS + NVMF root）。
# 调用签名保持 host 侧原样：mkZedGuest {inherit nixpkgs home-manager;}
{
  nixosSystem,
  common-nixos-modules,
  commonSpecialArgs,
  netboot,
  variants,
  username,
}: {
  nixpkgs,
  home-manager,
  ...
}:
nixosSystem {
  inherit nixpkgs home-manager;
  system = "x86_64-linux";
  specialArgs = commonSpecialArgs;
  nixos-modules =
    [../hosts/zed]
    ++ common-nixos-modules
    ++ [
      (variants.nixosModule "kde")
      netboot.nfsRoot
      (netboot.nvmfRoot {})
      netboot.disableEfi
    ];
  home-module = variants.mkHomeModule username "kde";
}
