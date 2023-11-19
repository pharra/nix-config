{
  config,
  pkgs,
  lib,
  ...
} @ args: {
  imports = [
    ./hardware-configuration.nix
  ];

  system.stateVersion = config.system.nixos.release;
}
