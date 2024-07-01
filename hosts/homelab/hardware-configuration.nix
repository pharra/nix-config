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
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "sr_mod" "uas" "xhci_pci"];
  boot.initrd.kernelModules = [
    "zfs"
  ];
  boot.blacklistedKernelModules = ["ast"];
  boot.kernelParams = ["default_hugepagesz=1G" "hugepagesz=1G" "hugepages=34" "amd_pstate=active" "amd_pstate.shared_mem=1" "pci=realloc"];
  boot.kernelModules = ["kvm-amd"];
  boot.extraModulePackages = with config.boot.kernelPackages; [
    cpupower
    (pkgs.mlnx_ofed.overrideAttrs (_: {
      kernel = kernel;
    }))
  ];

  # Enable nested virsualization, required by security containers and nested vm.
  # boot.extraModprobeConfig = "options kvm_intel nested=1"; # for intel cpu
  boot.extraModprobeConfig = ''
    options kvm_amd nested=1
    options kvm ignore_msrs=1 report_ignored_msrs=0
  ''; # for amd cpu

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
    cpufreq = {
      min = 3000000;
      max = 3500000;
    };
  };

  hardware.mlx4 = {
    enable = true;
    opensm = true;
    portTypeArray = "2,2";
  };

  specialisation = {
    vfio.configuration = {
      virtualisation.vfio.devices = [
      ];
    };
  };

  virtualisation.vfio = {
    enable = true;
    IOMMUType = "amd";
    devices = [
      "10de:21c4" # Graphics
      "10de:1aeb" # Audio
      "10de:1aec" # USB
      "10de:1aed" # UCSI

      # gtx 960
      "10de:1401"
      "10de:0fba"

      # RTX 4090
      "10de:2684"
      "10de:22ba"

      # intel 760p
      "8086:f1a6"

      #"1e4b:1202" # nvme
      #"1e4b:1602" # nvme
    ];
    applyACSpatch = true;
  };

  fileSystems."/system" = {
    device = "system";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/nix" = {
    device = "system/nix";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/nix/persistent" = {
    device = "system/persistent";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-label/zfs_boot";
    fsType = "vfat";
  };

  swapDevices = [];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno2.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp129s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp129s0d1.useDHCP = lib.mkDefault true;
  # networking.interfaces.usb0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
