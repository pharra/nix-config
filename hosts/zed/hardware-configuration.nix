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

  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "uas" "xhci_pci"];
  # boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-amd"];
  boot.extraModulePackages = [];
  # boot.kernelParams = lib.mkForce ["console=ttyS0"];

  virtualisation.vfio = {
    enable = true;
    IOMMUType = "amd";
    applyACSpatch = true;
    devices = [
      "10de:2684" # Graphics
      "10de:22ba" # Audio
      "8086:f1a6" # nvme
      #"10de:1aec" # USB
      #"10de:1aed" # UCSI
    ];
  };

  hardware.mlx5 = {
    enable = true;
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
