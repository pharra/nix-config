{
  lib,
  pkgs,
  username,
  config,
  ...
}: {
  ###################################################################################
  #
  #  Enable Libvirt(QEMU/KVM), install qemu-system-riscv64/qemu-system-loongarch64/...)
  #
  ###################################################################################

  virtualisation = {
    libvirtd = {
      enable = true;
      # hanging this option to false may cause file permission issues for existing guests.
      # To fix these, manually change ownership of affected files in /var/lib/libvirt/qemu to qemu-libvirtd.
      qemu.runAsRoot = true;
      qemu.ovmf.enable = true;
      qemu.swtpm.enable = true;
      qemu.ovmf.packages = [pkgs.OVMFFull.fd];
      onShutdown = "shutdown";
      qemu.verbatimConfig = ''
        namespaces = []
        cgroup_device_acl = [
          "/dev/null", "/dev/full", "/dev/zero",
          "/dev/random", "/dev/urandom",
          "/dev/ptmx", "/dev/kvm",
          "/dev/kvmfr0"
        ]
      '';
    };
  };
  programs.dconf.enable = true;
  environment.systemPackages = with pkgs; [
    # Need to add [File (in the menu bar) -> Add connection] after start the first time
    virt-manager

    # QEMU/KVM, provides:
    #   qemu-storage-daemon qemu-edid qemu-ga
    #   qemu-pr-helper qemu-nbd elf2dmp qemu-img qemu-io
    #   qemu-kvm qemu-system-x86_64 qemu-system-aarch64 qemu-system-i386
    # qemu_kvm

    # Install all packages about QEMU, provides:
    #   ......
    #   qemu-loongarch64 qemu-system-loongarch64
    #   qemu-riscv64 qemu-system-riscv64 qemu-riscv32  qemu-system-riscv32
    #   qemu-system-arm qemu-arm qemu-armeb qemu-system-aarch64 qemu-aarch64 qemu-aarch64_be
    #   qemu-system-xtensa qemu-xtensa qemu-system-xtensaeb qemu-xtensaeb
    #   ......
    # qemu_full

    looking-glass-client

    cloud-hypervisor

    docker-compose

    # swtpm
  ];

  # systemd.tmpfiles.rules = [
  #   "f /dev/shm/looking-glass 0660 ${username} libvirtd -"
  # ];

  environment.etc = {
    "ovmf/edk2-x86_64-secure-code.fd" = {
      source = config.virtualisation.libvirtd.qemu.package + "/share/qemu/edk2-x86_64-secure-code.fd";
    };

    "ovmf/edk2-i386-vars.fd" = {
      source = config.virtualisation.libvirtd.qemu.package + "/share/qemu/edk2-i386-vars.fd";
    };

    "ovmf/OVMF_CODE.ms.fd" = {
      source = "${pkgs.OVMFFull.fd}/FV/OVMF_CODE.ms.fd";
    };

    "ovmf/OVMF_VARS.ms.fd" = {
      source = "${pkgs.OVMFFull.fd}/FV/OVMF_VARS.ms.fd";
    };
  };

  boot.kernelModules = ["kvmfr"];
  boot.extraModulePackages = with config.boot.kernelPackages; [
    (kvmfr.overrideAttrs (_: {
      patches = [];
    }))
  ];
  boot.extraModprobeConfig = ''
    # 这里的内存大小计算方法和虚拟机的 shmem 一项相同。
    options kvmfr static_size_mb=256
  '';
  services.udev.extraRules = ''
    SUBSYSTEM=="kvmfr", OWNER="${username}", GROUP="libvirtd", MODE="0660"
  '';

  # NixOS VM should enable this:
  # services.qemuGuest = {
  #   enable = true;
  #   package = pkgs.qemu_kvm.ga;
  # };
}
