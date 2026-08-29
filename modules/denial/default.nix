{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib; let
  cfg = config.services.pharra.denial;
in {
  options = {
    services.pharra.denial = {
      enable = mkEnableOption "Denial desktop environment";
    };
  };

  config = mkIf cfg.enable {
    services.denial = {
      enable = true;
      user = "${username}";
    };

    services.displayManager.gdm.enable = true;
    services.displayManager.defaultSession = "denial";
    services.displayManager.sessionPackages = [
      config.services.denial.selectedPackage
    ];
  };
}
