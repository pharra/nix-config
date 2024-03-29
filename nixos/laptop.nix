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

  qt.enable = true;
  qt.platformTheme = "gnome";
  qt.style = "adwaita";

  boot.extraModulePackages = with config.boot.kernelPackages; [
    cpupower
  ];

  programs.mcontrolcenter = {
    enable = true;
  };

  powerManagement.powertop.enable = true;
  powerManagement.cpuFreqGovernor = "performance";

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  hardware.steam-hardware.enable = true;
  programs.steam = {
    enable = true;
  };
}
