{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.pharra.azure-tools;

  boot-vm = pkgs.writeShellScriptBin "boot-vm" (builtins.readFile ./boot-vm.sh);
  upload-image = pkgs.writeShellScriptBin "upload-image" (builtins.readFile ./upload-image.sh);
  replace-ip = pkgs.writeShellScriptBin "replace-ip" (builtins.readFile ./replace-ip.sh);
in {
  options = {
    services.pharra.azure-tools = {
      enable = mkEnableOption "Azure CLI and tools";
    };
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        # disable azure-cli as temporary workaround for https://github.com/NixOS/nixpkgs/pull/582594
        # azure-cli
        cacert
        azure-storage-azcopy
        jq

        boot-vm
        upload-image
        replace-ip
      ];
    };
  };
}
