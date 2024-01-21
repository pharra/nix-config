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
  # RTX 3070 Ti
  gpuIDs = [
    "10de:2684" # Graphics
    "10de:22ba" # Audio
    "8086:f1a6" # nvme
    #"10de:1aec" # USB
    #"10de:1aed" # UCSI
  ];
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.extraModprobeConfig = "options mlx4_core port_type_array=1,1 num_vfs=8 probe_vf=8 msi_x=1 enable_4k_uar=1 enable_qos=1 log_num_mac=7 log_num_mgm_entry_size=-1 log_mtts_per_seg=4";

  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "uas" "xhci_pci"];
  boot.initrd.kernelModules = [
    "mlx4_core"
    "mlx4_en"
    "mlx4_ib"
    "ib_ipoib"
    "ib_umad"
    "ib_srpt"
    "ib_iser"
    "ib_uverbs"
    "rdma_ucm"
    "xprtrdma"
    "svcrdma"

    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
  ];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  boot.kernelParams =
    #  "pci=nommconf"
    ["intel_iommu=on" "iommu=pt" "pcie_acs_override=downstream,multifunction"]
    ++ [("vfio-pci.ids=" + lib.concatStringsSep "," gpuIDs)]; # isolate the GPU

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
