# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
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
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  environment = {
    systemPackages = with pkgs; [
      add_monitor
      remove_monitor
    ];
  };

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  specialisation = {
    no-nvidia.configuration = {
      hardware.nvidia.prime = {
        offload = {
          enable = true;
          enableOffloadCmd = false;
        };
        # Make sure to use the correct Bus ID values for your system!
        # intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
        amdgpuBusId = "PCI:7:0:0"; # For AMD GPU
      };

      environment.variables = {
        # KWIN_DRM_DEVICES = "/dev/dri/card0:/dev/dri/card1";
        __EGL_VENDOR_LIBRARY_FILENAMES = "${pkgs.mesa.drivers}/share/glvnd/egl_vendor.d/50_mesa.json";
        __GLX_VENDOR_LIBRARY_NAME = "mesa";
        #VK_ICD_FILENAMES="/usr/share/vulkan/icd.d/radeon_icd.x86_64.json";
      };

      services.displayManager.sddm.settings = {
        General = {
          GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell,__EGL_VENDOR_LIBRARY_FILENAMES=${pkgs.mesa.drivers}/share/glvnd/egl_vendor.d/50_mesa.json,__GLX_VENDOR_LIBRARY_NAME=mesa";
        };
      };

      environment.systemPackages = [
        (pkgs.writeShellScriptBin "nvidia-offload" ''
          export __NV_PRIME_RENDER_OFFLOAD=1
          export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
          export __GLX_VENDOR_LIBRARY_NAME=nvidia
          export __VK_LAYER_NV_optimus=NVIDIA_only
          export __EGL_VENDOR_LIBRARY_FILENAMES=${config.hardware.nvidia.package}/share/glvnd/egl_vendor.d/10_nvidia.json
          exec "$@"
        '')
      ];
    };
  };

  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "uas" "xhci_pci"];
  # boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-amd"];
  boot.extraModulePackages = [];
  # "console=ttyS0"
  boot.kernelParams = ["default_hugepagesz=1G" "hugepagesz=1G" "hugepages=32" "amd_pstate=active" "amd_pstate.shared_mem=1"];
  boot.extraModprobeConfig = ''
    options kvm_amd nested=1
    softdep nvme pre: vfio-pci
  ''; # for amd cpu

  virtualisation.vfio = {
    enable = true;
    IOMMUType = "amd";
    applyACSpatch = false;
    ignoreMSRs = true;
    devices = [
      "10de:2684" # Graphics
      "10de:22ba" # Audio
      "8086:f1a6" # nvme
    ];
    blacklistNvidia = true;
  };

  hardware.mlx5 = {
    enable = true;
    enableSRIOV = true;
    interfaces = ["mlx5_0"];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    neededForBoot = true;
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
