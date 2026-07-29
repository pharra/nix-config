{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.pharra.base;
in {
  options = {
    services.pharra.base = {
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
