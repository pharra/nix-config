{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.pharra.no-desktop;
in {
  options = {
    services.pharra.no-desktop = {
      enable = mkEnableOption "base environment";
    };
  };

  config = mkIf cfg.enable {
    xdg.portal = {
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
    };
  };
}
