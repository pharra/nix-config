{
  lib,
  pkgs,
  username,
  config,
  ...
}: {
  ###################################################################################
  #
  #  Enable flatpak
  #
  ###################################################################################

  # https://flatpak.org/setup/NixOS
  services.flatpak.enable = true;
}
