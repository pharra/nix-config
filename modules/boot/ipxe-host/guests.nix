# 计算每个 NFS guest 的引导信息（内核 / initrd 路径、MAC、菜单里用的名字）。
# 被 guest-datasets.nix（建 ZFS 数据集）与 ipxe-server.nix（生成菜单）共用。
{
  lib,
  cfg,
}: let
  inherit (lib) mapAttrs;
in
  mapAttrs (
    name: guestCfg: let
      guestSystem = guestCfg.system;
      kernelParams = [
        "init=${guestSystem.config.system.build.toplevel}/init"
        "${toString guestSystem.config.boot.kernelParams}"
      ];
    in {
      inherit guestSystem kernelParams;
      macs = guestCfg.macs;
      kernelUrl = "${name}/bzImage";
      initrdUrl = "${name}/initrd";
      kernelPath = guestSystem.config.system.build.kernel + "/bzImage";
      initrdPath = guestSystem.config.system.build.initialRamdisk + "/initrd";
    }
  )
  cfg.nfs.guests
