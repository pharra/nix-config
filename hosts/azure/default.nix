{
  config,
  pkgs,
  lib,
  is_azure ? false,
  domain ? false,
  deploy-rs ? false,
  ...
} @ args: {
  imports =
    [
      # Include the results of the hardware scan.
      ./system.nix

      ../../secrets/nixos.nix
    ]
    ++ lib.optional is_azure ./sever;

  environment.systemPackages = lib.mkIf is_azure [deploy-rs.defaultPackage.x86_64-linux];

  # enable flakes globally
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # do garbage collection weekly to keep disk usage low
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 1d";
  };
}
