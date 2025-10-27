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
      allowedBridges = ["br0" "br1" "br2"];
      # hanging this option to false may cause file permission issues for existing guests.
      # To fix these, manually change ownership of affected files in /var/lib/libvirt/qemu to qemu-libvirtd.
      qemu.runAsRoot = true;
      qemu.swtpm.enable = true;
      onShutdown = "shutdown";
      qemu.verbatimConfig = ''
        namespaces = []
        cgroup_device_acl = [
          "/dev/null", "/dev/full", "/dev/zero",
          "/dev/random", "/dev/urandom",
          "/dev/ptmx", "/dev/kvm",
          "/dev/kvmfr0",
          "/dev/nvidiactl", "/dev/nvidia0", "/dev/nvidia-modeset", "/dev/dri/renderD128"
        ]
      '';
    };
  };

  boot.kernelModules = ["kvmfr"];
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

  environment.systemPackages = with pkgs; [
    virt-manager

    looking-glass-client
  ];
}
