{
  lib,
  pkgs,
  username,
  config,
  ...
}: 
{
  ###################################################################################
  #
  #  Enable Libvirt(QEMU/KVM), install qemu-system-riscv64/qemu-system-loongarch64/...)
  #
  ###################################################################################

  nixpkgs.overlays = [
    (self: super:
    {
      looking-glass-client = super.looking-glass-client.overrideAttrs (oldAttrs: rec {
        src = super.fetchFromGitHub {
          owner = "gnif";
          repo = "LookingGlass";
          rev = "219c73edbe33cfb34b5f4d1ea64937e8441cab44";
          sha256 = "sha256-WGhkKzEmrnvMRzcY4Y9rMWBEzXOlohfeD2EmuNQWCEk=";
          fetchSubmodules = true;
        };
      });
    })
  ];

  virtualisation = {
    libvirtd = {
      enable = true;
      # hanging this option to false may cause file permission issues for existing guests.
      # To fix these, manually change ownership of affected files in /var/lib/libvirt/qemu to qemu-libvirtd.
      qemu.runAsRoot = true;
      qemu.ovmf.enable = true;
      qemu.swtpm.enable = true;
      qemu.ovmf.packages = [ pkgs.OVMFFull ];
      onShutdown = "shutdown";
      qemu.verbatimConfig = ''
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
    qemu_kvm

    # Install all packages about QEMU, provides:
    #   ......
    #   qemu-loongarch64 qemu-system-loongarch64
    #   qemu-riscv64 qemu-system-riscv64 qemu-riscv32  qemu-system-riscv32
    #   qemu-system-arm qemu-arm qemu-armeb qemu-system-aarch64 qemu-aarch64 qemu-aarch64_be
    #   qemu-system-xtensa qemu-xtensa qemu-system-xtensaeb qemu-xtensaeb
    #   ......
    qemu_full

    looking-glass-client

    swtpm
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
};

  boot.kernelModules = ["kvm-amd" "kvm-intel" "kvmfr"];
  boot.extraModulePackages = with config.boot.kernelPackages; [
    kvmfr
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
