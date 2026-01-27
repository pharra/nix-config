{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.home.pharra.cosmic;
in {
  options = {
    home.pharra.cosmic = {
      enable = mkEnableOption "COSMIC home configuration";
    };
  };

  config = mkIf cfg.enable {
    # allow fontconfig to discover fonts and configurations installed through home.packages
    fonts.fontconfig.enable = true;

    systemd.user.sessionVariables = {
      "NIXOS_OZONE_WL" = "1"; # for any ozone-based browser & electron apps to run on wayland
      "MOZ_ENABLE_WAYLAND" = "1"; # for firefox to run on wayland
      "MOZ_WEBRENDER" = "1";
      "QT_QPA_PLATFORM" = "wayland";
    };

    programs = {
      firefox = {
        enable = true;
        enableGnomeExtensions = false;
      };

      vscode = {
        enable = true;
      };
    };
  };
}
