{
  config,
  lib,
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
    programs.denial.enable = true;
    programs.denial.plugins.enable = true; # Optional Plugin Manager.

    services.displayManager.gdm.enable = true;
    services.displayManager.defaultSession = "denial";

    environment.sessionVariables = {
      "NIXOS_OZONE_WL" = "1";
      "MOZ_ENABLE_WAYLAND" = "1";
      "MOZ_WEBRENDER" = "1";
      "QT_QPA_PLATFORM" = "wayland";
    };
  };
}
