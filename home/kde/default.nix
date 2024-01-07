{pkgs, ...}: {
  imports = [
    ./kde-apps.nix
  ];

  # allow fontconfig to discover fonts and configurations installed through home.packages
  fonts.fontconfig.enable = true;
}
