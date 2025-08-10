{
  lib,
  pkgs,
  config,
  libs,
  ...
}: let
  swtpm-scripts = pkgs.writeShellScriptBin "swtpm-scripts" ''
    ${pkgs.swtpm}/bin/swtpm socket --ctrl type=unixio,path=/run/microsoft-swtpm.sock,mode=0600 \
    --tpmstate dir=/var/lib/swtpm/microsoft,mode=0600 \
    --log file=/var/log/microsoft-swtpm.log \
    --terminate --tpm2
  '';

  qemu-scripts = pkgs.writeShellScriptBin "qemu-scripts" ''
    ${swtpm-scripts}/bin/swtpm-scripts &
    ${pkgs.qemu}/bin/qemu-system-x86_64 -cpu host -enable-kvm -smp 4 \
    -m 4G -object memory-backend-file,id=mem0,size=4G,mem-path=/dev/hugepages,share=on,prealloc=yes, -numa node,memdev=mem0 \
    -bios /run/libvirt/nix-ovmf/OVMF_CODE.fd -machine pc-q35-8.1 \
    -nic user,model=virtio-net-pci \
    -chardev socket,id=chrtpm,path=/run/microsoft-swtpm.sock -tpmdev emulator,id=tpm-tpm0,chardev=chrtpm -device tpm-crb,tpmdev=tpm-tpm0,id=tpm0 \
    -chardev socket,id=char1,path=/var/run/vhost.1 -device vhost-user-blk-pci,id=blk0,chardev=char1 \
    -chardev pty,id=charserial0 -device isa-serial,chardev=charserial0,id=serial0,index=0 \
    -device qxl-vga \
    -boot menu=on,strict=on

    -object {"qom-type":"secret","id":"masterKey0","format":"raw","file":"/var/lib/libvirt/qemu/domain-25-microsoft/master-key.aes"} -blockdev {"driver":"file","filename":"/run/libvirt/nix-ovmf/OVMF_CODE.fd","node-name":"libvirt-pflash0-storage","auto-read-only":true,"discard":"unmap"} -blockdev {"node-name":"libvirt-pflash0-format","read-only":true,"driver":"raw","file":"libvirt-pflash0-storage"} -blockdev {"driver":"file","filename":"/var/lib/libvirt/qemu/nvram/microsoft_VARS.fd","node-name":"libvirt-pflash1-storage","auto-read-only":true,"discard":"unmap"} -blockdev {"node-name":"libvirt-pflash1-format","read-only":false,"driver":"raw","file":"libvirt-pflash1-storage"}
  '';

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
in {
  environment.systemPackages = with pkgs; [
    swtpm-scripts
    qemu-scripts
    init-fluent-disk
    mount-fluent
    umount-fluent
  ];
}
