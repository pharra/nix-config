{
  config,
  pkgs,
  ...
} @ args:
#############################################################
#
#  Ai - my main computer, with NixOS + I5-13600KF + RTX 4090 GPU, for gaming & daily use.
#
#############################################################
{
  imports = [
    # Include the results of the hardware scan.
    ./system.nix

    ../../secrets/nixos.nix
  ];

  environment.systemPackages = with pkgs; [
    xray
  ];
}
