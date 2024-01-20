{
  pkgs,
  lib,
  config,
  utils,
  inputs,
  ...
} @ args: {
  # Laptop can't correctly suspend if wlan is active
  powerManagement = {
    powerDownCommands = ''
      ${pkgs.util-linux}/bin/rfkill block wlan
    '';
    resumeCommands = ''
      ${pkgs.util-linux}/bin/rfkill unblock wlan
    '';
  };

  services.thermald.enable = true;

  powerManagement.powertop.enable = true;

  hardware.steam-hardware.enable = true;
  programs.steam = {
    enable = true;
  };
}
