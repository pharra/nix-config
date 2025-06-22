{
  config,
  pkgs,
  lib,
  boot_from_network,
  ...
} @ args: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../../nixos/libvirt.nix
    ../../nixos/core-desktop.nix
    ../../nixos/user-group.nix
    ../../nixos/wsl.nix
  ];

  # supported fil systems, so we can mount any removable disks with these filesystems
  boot.supportedFilesystems = [
    "ext4"
    "btrfs"
    "xfs"
    #"zfs"
    "ntfs"
    "fat"
    "vfat"
    "exfat"
    "cifs" # mount windows share
    "nfs"
  ];

  environment = {
    sessionVariables = {
      GALLIUM_DRIVER = "d3d12";
      MESA_D3D12_DEFAULT_ADAPTER_NAME = "NVIDIA";
      # LIBGL_KOPPER_DRI2 = "true"; # Fixes openGL in WSL, not really sure what is does.
    };
  };

  networking = {
    hostName = "dat";
    domain = "lan";

    networkmanager.enable = true;
    networkmanager.unmanaged = ["*,except:interface-name:wl*"];
  };

  system.stateVersion = "24.05"; # Did you read the comment?
}
