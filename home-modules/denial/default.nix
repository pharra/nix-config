{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.home.pharra.denial;
in {
  options = {
    home.pharra.denial = {
      enable = mkEnableOption "Denial home configuration";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.sessionVariables = {
      "NIXOS_OZONE_WL" = "1"; # for any ozone-based browser & electron apps to run on wayland
      "MOZ_ENABLE_WAYLAND" = "1"; # for firefox to run on wayland
      "MOZ_WEBRENDER" = "1";
      "QT_QPA_PLATFORM" = "wayland";
    };
  };
}
