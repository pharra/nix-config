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
    programs.denial.enable = true;
    programs.denial.plugins.enable = true; # Optional Plugin Manager.

    services.displayManager.regreet.enable = true;
    services.displayManager.defaultSession = "denial";

    services.pharra.kwallet-shim.enable = true;
    services.pharra.kwallet-shim.xdgCurrentDesktop = "denial:KDE";
    services.pharra.waywallen-layer-shell.enable = true;

    environment.systemPackages = with pkgs; [
      alacritty
    ];

    environment.sessionVariables = {
      "NIXOS_OZONE_WL" = "1";
      "MOZ_ENABLE_WAYLAND" = "1";
      "MOZ_WEBRENDER" = "1";
      "QT_QPA_PLATFORM" = "wayland";
    };
  };
}
