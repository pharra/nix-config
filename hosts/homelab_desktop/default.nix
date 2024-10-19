{
  config,
  lib,
  ...
} @ args:
#############################################################
#
#  Ai - my main computer, with NixOS + I5-13600KF + RTX 4090 GPU, for gaming & daily use.
#
#############################################################
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../../nixos/fhs-fonts.nix
    ../../nixos/libvirt.nix
    ../../nixos/core-desktop.nix
    # ../../nixos/remote-building.nix
    ../../nixos/user-group.nix

    ../../secrets/nixos.nix
  ];

  # Enable binfmt emulation of aarch64-linux, this is required for cross compilation.
  boot.binfmt.emulatedSystems = ["aarch64-linux" "riscv64-linux"];
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
  ];

  # Bootloader.
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi"; # ← use the same mount point here.
    };
    systemd-boot.enable = true;
  };

  networking.firewall.enable = lib.mkForce false;
  networking = {
    hostName = "homelab-desktop";
    wireless.enable = false; # Enables wireless support via wpa_supplicant.

    networkmanager.enable = true;
    networkmanager.unmanaged = ["*,except:interface-name:wlp*"];
  };

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;

    networks = {
      # Configure the bridge for its desired function
      "40-en" = {
        matchConfig.Name = "en*";
        networkConfig = {
          # start a DHCP Client for IPv4 Addressing/Routing
          DHCP = "ipv4";
          # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
          IPv6AcceptRA = true;
        };
        linkConfig = {
          # or "routable" with IP addresses configured
          RequiredForOnline = "routable";
        };
      };
    };
  };

  services.resolved = {
    enable = true;
  };

  #virtualisation.docker.storageDriver = "btrfs";

  # for Nvidia GPU
  services.xserver.videoDrivers = ["nvidia"]; # will install nvidia-vaapi-driver by default
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    forceFullCompositionPipeline = true;
    #open = true;
    #powerManagement.enable = true;
  };
  # virtualisation.docker.enableNvidia = true; # for nvidia-docker

  hardware.graphics = {
    enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
