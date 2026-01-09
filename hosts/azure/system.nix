{
  pkgs,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    "${modulesPath}/virtualisation/azure-image.nix"
  ];

  image.fileName = "nixos.vhd";
  virtualisation.azureImage.vmGeneration = "v2";
  virtualisation.diskSize = 8 * 1024;
  virtualisation.azure.acceleratedNetworking = true;

  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  virtualisation.docker = {
    enable = true;
    daemon.settings.features.cdi = true;
    daemon.settings.live-restore = false; # avoid docker container hanging on shutdown
    daemon.settings.dns = ["114.114.114.114"]; # if not set, docker compose will fail to resolve hostnames
  };

  system.stateVersion = "25.05";
}
