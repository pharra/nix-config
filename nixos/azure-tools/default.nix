{
  lib,
  pkgs,
  config,
  libs,
  ...
}: let
  boot-vm = pkgs.writeShellScriptBin "boot-vm" (builtins.readFile ./boot-vm.sh);
  upload-image = pkgs.writeShellScriptBin "upload-image" (builtins.readFile ./upload-image.sh);
in {
  environment = {
    systemPackages = with pkgs; [
      azure-cli
      cacert
      azure-storage-azcopy
      jq

      boot-vm
      upload-image
    ];
  };
}
