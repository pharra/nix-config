# MSI GF65（笔记本；注意 hostname 是 nix65，不是 gs65）。
# 配置名：gs65（desktop = kde，见 hosts/machines.nix）。
# 启用的功能：见本文件与 ./hardware-configuration.nix 里的 services.pharra / hardware.* enable 项。
{
  config,
  pkgs,
  ...
}:
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
    desktop.enable = true;
  };

  networking = {
    hostName = "nix65";
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

  hardware.mcontrolcenter = {
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
  # 需要 nvidia 驱动时把 "nvidia" 加进下面的列表（它是 nvidia 模块的开关）。
  services.xserver.videoDrivers = ["displaylink" "modesetting"];

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    powerManagement.enable = true;
  };

  # 下面两段是可选配置（当前未启用）：PRIME 独显直连/offload、以及强制 EGL 用 mesa。
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
  system.stateVersion = "26.05"; # Did you read the comment?
}
