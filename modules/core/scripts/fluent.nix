# fluent disk 相关脚本（初始化 / 挂载 / 卸载）。
# 字符串连同缩进原样搬过来，所以 Nix 插值与转义语义都不变。
{pkgs}: rec {
  init = ''
    zpool create -f -o ashift=14 fluent /dev/zvol/data/fluent_system
    mkfs.btrfs -L fluent_nix -f /dev/zvol/data/fluent_nix
    mkfs.vfat -n fluent_boot /dev/zvol/data/fluent_boot-part1

    zfs create fluent/nix
    zfs create fluent/nix/persistent
    zfs create fluent/nix/var
    zfs create fluent/tmp

    zpool export fluent
  '';

  mount = ''
    zpool import -f fluent

    mkdir /fluent/boot/efi -p
    mount /dev/disk/by-label/fluent_boot /fluent/boot/efi

    mkdir /fluent/nix/store -p
    mount -t btrfs -o compress-force=zstd:19 /dev/disk/by-label/fluent_nix /fluent/nix/store
  '';

  umount = ''
    umount /fluent/nix/store
    umount /fluent/boot/efi

    zpool export -f fluent
  '';
}
