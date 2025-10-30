{
  lib,
  pkgs,
  config,
  libs,
  ...
}: let
  init-fluent-disk = pkgs.writeShellScriptBin "init-fluent-disk" ''
    zpool create -f -o ashift=14 fluent /dev/zvol/data/fluent_system
    mkfs.btrfs -L fluent_nix -f /dev/zvol/data/fluent_nix
    mkfs.vfat -n fluent_boot /dev/zvol/data/fluent_boot-part1

    zfs create fluent/nix
    zfs create fluent/nix/persistent
    zfs create fluent/nix/var
    zfs create fluent/tmp

    zpool export fluent
  '';

  mount-fluent = pkgs.writeShellScriptBin "mount-fluent" ''
    zpool import -f fluent

    mkdir /fluent/boot/efi -p
    mount /dev/disk/by-label/fluent_boot /fluent/boot/efi

    mkdir /fluent/nix/store -p
    mount -t btrfs -o compress-force=zstd:19 /dev/disk/by-label/fluent_nix /fluent/nix/store
  '';

  umount-fluent = pkgs.writeShellScriptBin "umount-fluent" ''
    umount /fluent/nix/store
    umount /fluent/boot/efi

    zpool export -f fluent
  '';

  custom_edid = pkgs.runCommand "edid-custom" {} ''
    mkdir -p "$out/lib/firmware/edid"

    # this edid you can copy from your real monitor, check below

    base64 -d > "$out/lib/firmware/edid/custom1.bin" <<'EOF'
    AP///////wAx2DQSAAAAACIaAQOAYDZ4D+6Ro1RMmSYPUFQvzwAxWUVZgYCBQJBAlQCpQLMACOgAMPJwWoCwWIoAwBwyAAAeAAAA/QAYVRiHPAAKICAgICAgAAAA/AB2aXZpZAogICAgICAgAAAAEAAAAAAAAAAAAAAAAAAAAXsCAz/xUWFgX15dEB8EEyIhIAUUAhEBIwkHB4MBAABtAwwAEAAAPCEAYAECA2fYXcQBeAAA4gDK4wUAAOMGAQBN0ACg8HA+gDAgNQDAHDIAAB4aNoCgcDgfQDAgNQDAHDIAABoaHQCAUdAcIECANQDAHDIAABwAAAAAAAAAAAAAgg==
    EOF
  '';
  add_monitor = pkgs.writeShellScriptBin "add_monitor" ''
    gpu_vendor="1002:164e"
    gpu_bus_path=`${pkgs.pciutils}/bin/lspci -mm -d $gpu_vendor | ${pkgs.gawk}/bin/awk '{ print $1 }'`
    ${pkgs.coreutils-full}/bin/cat ${custom_edid}/lib/firmware/edid/custom1.bin > /sys/kernel/debug/dri/0000:$gpu_bus_path/DP-2/edid_override
    ${pkgs.coreutils-full}/bin/echo -n "on" | ${pkgs.coreutils-full}/bin/tee /sys/kernel/debug/dri/0000:$gpu_bus_path/DP-2/force
    ${pkgs.coreutils-full}/bin/echo -n "1" | ${pkgs.coreutils-full}/bin/tee /sys/kernel/debug/dri/0000:$gpu_bus_path/DP-2/trigger_hotplug
  '';
  remove_monitor = pkgs.writeShellScriptBin "remove_monitor" ''
    gpu_vendor="1002:164e"
    gpu_bus_path=`${pkgs.pciutils}/bin/lspci -mm -d $gpu_vendor | ${pkgs.gawk}/bin/awk '{ print $1 }'`
    ${pkgs.coreutils-full}/bin/echo -n "reset" | ${pkgs.coreutils-full}/bin/tee /sys/kernel/debug/dri/0000:$gpu_bus_path/DP-2/edid_override
    ${pkgs.coreutils-full}/bin/echo -n "off" | ${pkgs.coreutils-full}/bin/tee /sys/kernel/debug/dri/0000:$gpu_bus_path/DP-2/force
    ${pkgs.coreutils-full}/bin/echo -n "1" | ${pkgs.coreutils-full}/bin/tee /sys/kernel/debug/dri/0000:$gpu_bus_path/DP-2/trigger_hotplug
  '';
in {
  environment.systemPackages = with pkgs; [
    init-fluent-disk
    mount-fluent
    umount-fluent
    add_monitor
    remove_monitor

    spdk-python
  ];
}
