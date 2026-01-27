{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib; let
  cfg = config.services.pharra.cosmic;
in {
  options = {
    services.pharra.cosmic = {
      enable = mkEnableOption "COSMIC desktop environment";
    };
  };

  config = mkIf cfg.enable {
    services.blueman.enable = true;

    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;
  };
}
