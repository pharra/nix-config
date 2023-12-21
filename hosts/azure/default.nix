{
  config,
  pkgs,
  lib,
  is_azure ? false,
  domain ? false,
  ...
} @ args: {
  imports =
    [
      # Include the results of the hardware scan.
      ./system.nix

      ../../secrets/nixos.nix
    ]
    ++ lib.optional is_azure ./sever;
}
