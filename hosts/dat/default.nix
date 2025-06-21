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

  networking = {
    hostName = "dat";
    domain = "lan";

    networkmanager.enable = true;
    networkmanager.unmanaged = ["*,except:interface-name:wl*"];
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  wsl = {
    enable = true;
    defaultUser = "wf";
  };

  system.stateVersion = "24.05"; # Did you read the comment?
}
