# 在 homelab 上运行的 zed 网络启动 guest 系统（NFS + NVMF root）。
{
  nixosSystem,
  common-nixos-modules,
  commonSpecialArgs,
  netboot,
  variants,
}: {nixpkgs, ...}:
nixosSystem {
  inherit nixpkgs;
  system = "x86_64-linux";
  specialArgs = commonSpecialArgs;
  nixos-modules =
    [../../../hosts/zed]
    ++ common-nixos-modules
    ++ [
      (variants.nixosModule "kde")
      netboot.nfsRoot
      (netboot.nvmfRoot {})
      netboot.disableEfi
    ];
}
