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

  system.stateVersion = "25.05";
}
