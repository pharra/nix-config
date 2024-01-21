{
  config,
  pkgs,
  lib,
  ...
} @ args: {
  imports = [
    ./hardware-configuration.nix
    ../../nixos/user-group.nix
  ];

  system.stateVersion = config.system.nixos.release;
  environment.noXlibs = false;
}
