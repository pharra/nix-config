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

  spdk-iscsi-scripts = pkgs.writeShellScriptBin "spdk-iscsi-scripts" ''
    ${pkgs.spdk}/scripts/rpc.py bdev_aio_create /dev/zvol/data/windata windata
    ${pkgs.spdk}/scripts/rpc.py bdev_aio_create /dev/zvol/data/desktop_nixos nixos
    ${pkgs.spdk}/scripts/rpc.py iscsi_create_initiator_group 1 ANY ANY
    ${pkgs.spdk}/scripts/rpc.py iscsi_create_initiator_group 2 ANY ANY
    ${pkgs.spdk}/scripts/rpc.py iscsi_create_initiator_group 3 ANY ANY
    ${pkgs.spdk}/scripts/rpc.py iscsi_create_portal_group 1 192.168.29.1:3260
    ${pkgs.spdk}/scripts/rpc.py iscsi_create_portal_group 2 192.168.30.1:3260
    ${pkgs.spdk}/scripts/rpc.py iscsi_create_portal_group 3 192.168.28.1:3260
    ${pkgs.spdk}/scripts/rpc.py iscsi_create_target_node data data_alias windata:0 '1:1 2:2 3:3' 64 -d
    ${pkgs.spdk}/scripts/rpc.py iscsi_create_target_node nixos nixos_alias nixos:0 '1:1 2:2 3:3' 64 -d
  '';

  spdk-nvmf-scripts = pkgs.writeShellScriptBin "spdk-nvmf-scripts" ''
    ${pkgs.spdk}/scripts/rpc.py bdev_aio_create /dev/zvol/data/data1 data
    ${pkgs.spdk}/scripts/rpc.py nvmf_create_transport -t RDMA -u 8192 -i 131072 -c 8192
    ${pkgs.spdk}/scripts/rpc.py nvmf_create_subsystem nqn.2016-06.io.spdk:data -a -s SPDK00000000000001 -d SPDK_Controller1
    ${pkgs.spdk}/scripts/rpc.py nvmf_subsystem_add_ns nqn.2016-06.io.spdk:data data
    ${pkgs.spdk}/scripts/rpc.py nvmf_subsystem_add_listener nqn.2016-06.io.spdk:data -t rdma -a 192.168.30.1 -s 4420
    ${pkgs.spdk}/scripts/rpc.py nvmf_subsystem_add_listener nqn.2016-06.io.spdk:data -t rdma -a 192.168.29.1 -s 4420
  '';

  spdk-vhost-scripts = pkgs.writeShellScriptBin "spdk-vhost-scripts" ''
    ${pkgs.spdk}/scripts/rpc.py bdev_aio_create /dev/zvol/zp/microsoft microsoft
    ${pkgs.spdk}/scripts/rpc.py vhost_create_scsi_controller vhost.0
    ${pkgs.spdk}/scripts/rpc.py vhost_scsi_controller_add_target vhost.0 0 microsoft
  '';

  spdk-nvme-scripts = pkgs.writeShellScriptBin "spdk-nvme-scripts" ''
    ${pkgs.kmod}/bin/modprobe ublk_drv
    ${pkgs.spdk}/scripts/rpc.py bdev_nvme_attach_controller -b nvme1 -t pcie -a 0000:81:00.0
    ${pkgs.spdk}/scripts/rpc.py bdev_nvme_attach_controller -b nvme2 -t pcie -a 0000:82:00.0
    ${pkgs.spdk}/scripts/rpc.py bdev_nvme_attach_controller -b nvme3 -t pcie -a 0000:83:00.0
    ${pkgs.spdk}/scripts/rpc.py bdev_nvme_attach_controller -b nvme4 -t pcie -a 0000:84:00.0
    # ${pkgs.spdk}/scripts/rpc.py ublk_create_target
    # ${pkgs.spdk}/scripts/rpc.py ublk_start_disk nvme1n1 1 -q 2 -d 128
    # ${pkgs.spdk}/scripts/rpc.py ublk_start_disk nvme2n1 2 -q 2 -d 128
    # ${pkgs.spdk}/scripts/rpc.py ublk_start_disk nvme3n1 3 -q 2 -d 128
    # ${pkgs.spdk}/scripts/rpc.py ublk_start_disk nvme4n1 4 -q 2 -d 128
  '';

  spdk-scripts = pkgs.writeShellScriptBin "spdk-scripts" ''
    ${pkgs.spdk}/scripts/rpc.py nvmf_create_transport -t VFIOUSER
    ${pkgs.spdk}/scripts/rpc.py bdev_aio_create /dev/mapper/data-microsoft microsoft
    ${pkgs.spdk}/scripts/rpc.py nvmf_create_subsystem nqn.2019-07.io.spdk:microsoft -a -s SPDK0
    ${pkgs.spdk}/scripts/rpc.py nvmf_subsystem_add_ns nqn.2019-07.io.spdk:microsoft microsoft
    ${pkgs.spdk}/scripts/rpc.py nvmf_subsystem_add_listener nqn.2019-07.io.spdk:microsoft -t VFIOUSER -a /var/run -s 0
  '';

  bind-vfio-scripts = pkgs.writeShellScriptBin "bind-vfio-scripts" ''
    echo 0000:81:00.0 > /sys/bus/pci/drivers/nvme/unbind
    echo 0000:82:00.0 > /sys/bus/pci/drivers/nvme/unbind
    echo 0000:83:00.0 > /sys/bus/pci/drivers/nvme/unbind
    echo 0000:84:00.0 > /sys/bus/pci/drivers/nvme/unbind
    ${pkgs.spdk}/scripts/setup.sh
  '';

  unbind-vfio-scripts = pkgs.writeShellScriptBin "unbind-vfio-scripts" ''
    echo 0000:81:00.0 > /sys/bus/pci/drivers/vfio-pci/unbind
    echo 0000:82:00.0 > /sys/bus/pci/drivers/vfio-pci/unbind
    echo 0000:83:00.0 > /sys/bus/pci/drivers/vfio-pci/unbind
    echo 0000:84:00.0 > /sys/bus/pci/drivers/vfio-pci/unbind

    echo 0000:81:00.0 > /sys/bus/pci/drivers/nvme/bind
    echo 0000:82:00.0 > /sys/bus/pci/drivers/nvme/bind
    echo 0000:83:00.0 > /sys/bus/pci/drivers/nvme/bind
    echo 0000:84:00.0 > /sys/bus/pci/drivers/nvme/bind
  '';
in {
  environment.systemPackages = with pkgs; [
    swtpm-scripts
    qemu-scripts
    init-fluent-disk
    mount-fluent
    umount-fluent
    add_monitor
    remove_monitor

    #spdk-iscsi-scripts
    #spdk-nvmf-scripts
    #spdk-vhost-scripts
    #spdk-nvme-scripts
    #spdk-scripts
    bind-vfio-scripts
    unbind-vfio-scripts
    spdk-python
  ];
}
