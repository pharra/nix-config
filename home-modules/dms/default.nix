{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.home.pharra.dms;
  defaultNiriConfig = ./niri;
  defaultDmsConfig = ./dank-material-shell;
in {
  options = {
    home.pharra.dms = {
      enable = mkEnableOption "DMS home configuration";
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

    home.activation.installDmsAndNiriDefaults = lib.hm.dag.entryAfter ["writeBoundary"] ''
      copy_if_missing() {
        src="$1"
        dst="$2"

        if [ ! -e "$dst" ]; then
          install -Dm644 "$src" "$dst"
        fi
      }

      copy_if_missing "${defaultNiriConfig}/config.kdl" "${config.xdg.configHome}/niri/config.kdl"
      copy_if_missing "${defaultNiriConfig}/dms/binds.kdl" "${config.xdg.configHome}/niri/dms/binds.kdl"
      copy_if_missing "${defaultNiriConfig}/dms/colors.kdl" "${config.xdg.configHome}/niri/dms/colors.kdl"
      copy_if_missing "${defaultNiriConfig}/dms/layout.kdl" "${config.xdg.configHome}/niri/dms/layout.kdl"
      copy_if_missing "${defaultNiriConfig}/dms/alttab.kdl" "${config.xdg.configHome}/niri/dms/alttab.kdl"
      copy_if_missing "${defaultNiriConfig}/dms/wpblur.kdl" "${config.xdg.configHome}/niri/dms/wpblur.kdl"
      copy_if_missing "${defaultNiriConfig}/dms/outputs.kdl" "${config.xdg.configHome}/niri/dms/outputs.kdl"
      copy_if_missing "${defaultNiriConfig}/dms/cursor.kdl" "${config.xdg.configHome}/niri/dms/cursor.kdl"
      copy_if_missing "${defaultNiriConfig}/dms/windowrules.kdl" "${config.xdg.configHome}/niri/dms/windowrules.kdl"

      copy_if_missing "${defaultDmsConfig}/settings.json" "${config.xdg.configHome}/DankMaterialShell/settings.json"
      copy_if_missing "${defaultDmsConfig}/plugin_settings.json" "${config.xdg.configHome}/DankMaterialShell/plugin_settings.json"
      copy_if_missing "${defaultDmsConfig}/clsettings.json" "${config.xdg.configHome}/DankMaterialShell/clsettings.json"
    '';
  };
}
