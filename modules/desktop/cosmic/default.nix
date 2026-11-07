{
  config,
  lib,
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
    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;

    environment.sessionVariables = {
      "NIXOS_OZONE_WL" = "1";
      "MOZ_ENABLE_WAYLAND" = "1";
      "MOZ_WEBRENDER" = "1";
      "QT_QPA_PLATFORM" = "wayland";
    };
  };
}
