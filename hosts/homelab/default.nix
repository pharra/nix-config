# 服务器：ZFS 存储 + SPDK/NVMF 网络盘 + 一批容器服务；同时是 zed 网络启动（zed_net）的宿主侧。
# 配置名：homelab（desktop = base）。
# 启用的功能：见本文件与 ./hardware-configuration.nix 里的 services.pharra / hardware.* enable 项；
# libvirt 客机在 ./nixvirt；NFS/NVMF 导出给 guest 的部分在 modules/boot/netboot/netboot.nix 与 mkZedGuest.nix。
{config, ...}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../../secrets/nixos.nix

    ./nixvirt

    ../../services
    ./network.nix
    ./storage.nix
    ./guest.nix
  ];

  services.pharra = {
    nix-access-token.enable = true;
    desktop.enable = false;
    common.enable = true;
    preservation.enable = true;
    spdk-container.enable = true;
    sftp-server.enable = true;
    easytier.enable = true;
    scripts.enable = true;
    virtualisation.enable = true;
    azure-tools.enable = true;
    archlinux.enable = true;
  };

  # for Nvidia GPU
  # 这一行是 nixpkgs nvidia 模块的总开关（nvidiaEnabled = elem "nvidia" videoDrivers）。homelab 没有 X，
  # 但容器（nvidia-container-toolkit）要用驱动，所以必须留着；删掉它 GPU 容器就失效。
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.production;
    # modesetting.enable = true;
    # forceFullCompositionPipeline = true;
    open = true;
    # powerManagement.enable = true;
  };
  hardware.nvidia-container-toolkit.enable = true; # for nvidia-docker

  hardware.graphics = {
    enable = true;
  };

  services.logind.settings.Login = {
    HandlePowerKey = "ignore"; # 短按忽略
    # HandlePowerKeyLongPress = "ignore"; # 长按忽略（效果有限）
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
