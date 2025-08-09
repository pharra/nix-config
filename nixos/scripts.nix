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
    mkfs.btrfs -L fluent_system -f /dev/zvol/data/fluent_system
    mkfs.btrfs -L fluent_nix -f /dev/zvol/data/fluent_nix
    mkfs.vfat -n fluent_boot /dev/zvol/data/fluent_boot-part1

    mount -t btrfs -o compress=zstd /dev/zvol/data/fluent_system /fluent
    btrfs subvolume create /fluent/@nix-var
    btrfs subvolume create /fluent/@persistent
    btrfs subvolume create /fluent/@tmp
    umount /fluent
  '';

  mount-fluent = pkgs.writeShellScriptBin "mount-fluent" ''
    mkdir /fluent -p
    mount -t btrfs -o compress=zstd /dev/disk/by-label/fluent_system /fluent
    mkdir /fluent/boot/efi -p
    mount /dev/disk/by-label/fluent_boot /fluent/boot/efi
    mkdir /fluent/nix -p
    mount -t btrfs -o compress-force=zstd:15 /dev/disk/by-label/fluent_nix /fluent/nix
    mkdir /fluent/nix/persistent -p
    mount -t btrfs -o compress=zstd,subvol=@persistent /dev/disk/by-label/fluent_system /fluent/nix/persistent
    mkdir /fluent/tmp -p
    mount -t btrfs -o compress=zstd,subvol=@tmp /dev/disk/by-label/fluent_system /fluent/tmp
    mkdir /fluent/nix/var -p
    mount -t btrfs -o compress=zstd,subvol=@nix-var /dev/disk/by-label/fluent_system /fluent/nix/var
  '';

  umount-fluent = pkgs.writeShellScriptBin "umount-fluent" ''
    umount /fluent/nix/var
    umount /fluent/nix/persistent
    umount /fluent/nix
    umount /fluent/boot/efi
    umount /fluent/tmp
    umount /fluent
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
