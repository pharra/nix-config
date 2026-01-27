{
  config,
  pkgs,
  lib,
  ...
} @ args:
#############################################################
#
#  MSI GF65
#
#############################################################
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../../secrets/nixos.nix
  ];

  services.pharra = {
    libvirt.enable = true;
    core-desktop.enable = true;
    user-group.enable = true;
  };

  # Bootloader.
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi"; # ← use the same mount point here.
    };
    systemd-boot.enable = true;
  };

  networking = {
    hostName = "nix65";
    wireless.enable = false; # Enables wireless support via wpa_supplicant.

    networkmanager.enable = true;
  };

  # Laptop can't correctly suspend if wlan is active
  powerManagement = {
    powerDownCommands = ''
      ${pkgs.util-linux}/bin/rfkill block wlan
    '';
    resumeCommands = ''
      ${pkgs.util-linux}/bin/rfkill unblock wlan
    '';
  };

  services.thermald.enable = true;

  boot.extraModulePackages = with config.boot.kernelPackages; [
    cpupower
  ];

  programs.mcontrolcenter = {
    enable = true;
  };

  powerManagement.powertop.enable = true;
  powerManagement.cpuFreqGovernor = "performance";

  systemd.network = {
    networks = {
      "50-enp60s0" = {
        matchConfig.Name = "enp60s0";
        # acquire a DHCP lease on link up
        networkConfig.DHCP = "yes";
        # this port is not always connected and not required to be online
        linkConfig.RequiredForOnline = "yes";
      };
    };
  };

  # for Nvidia GPU
  # services.xserver.videoDrivers = ["nvidia"]; # will install nvidia-vaapi-driver by default
  services.xserver.videoDrivers = ["displaylink" "modesetting"];

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    powerManagement.enable = true;
  };

  # hardware.nvidia.prime = {
  #   offload = {
  #     enable = true;
  #     enableOffloadCmd = true;
  #   };
  #   # Make sure to use the correct Bus ID values for your system!
  #   intelBusId = "PCI:0:2:0";
  #   nvidiaBusId = "PCI:1:0:0";
  # };

  # environment.variables = {
  #   __EGL_VENDOR_LIBRARY_FILENAMES = "${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json";
  # };

  hardware = {
    graphics = {
      enable = true;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
