{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
with lib; let
  cfg = config.home.pharra.desktopShell;
  defaultNiriConfig = ./niri;
  defaultHyprlandConfig = ./hyprland;
  selectedNiriConfig = "${defaultNiriConfig}/${cfg.variant}";
  selectedHyprlandConfig = "${defaultHyprlandConfig}/${cfg.variant}";
  defaultDmsConfig = ./dank-material-shell;
  defaultNoctaliaConfig = ./noctalia-shell;
in {
  options = {
    home.pharra.desktopShell = {
      enable = mkEnableOption "Desktop shell home configuration";

      variant = mkOption {
        type = types.enum ["dms" "noctalia"];
        default = attrByPath ["services" "pharra" "desktopShell" "variant"] "dms" osConfig;
        description = "Desktop shell variant to configure (dms or noctalia).";
      };

      compositor = mkOption {
        type = types.enum ["niri" "hyprland"];
        default = attrByPath ["services" "pharra" "desktopShell" "compositor"] "niri" osConfig;
        description = "The Wayland compositor to use with this desktop shell (niri or hyprland)";
      };
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

      noctalia-shell = mkIf (cfg.variant == "noctalia") {
        enable = true;
        # When the NixOS module owns the systemd service, HM should not provide its own package wrapper.
        package = null;
      };
    };

    home.activation.installDmsAndCompositorDefaults = lib.hm.dag.entryAfter ["writeBoundary"] ''
      copy_if_missing_file() {
        src="$1"
        dst="$2"

        if [ ! -e "$dst" ]; then
          install -Dm644 "$src" "$dst"
        fi
      }

      copy_if_missing_dir() {
        src="$1"
        dst="$2"

        if [ -d "$src" ] && [ ! -e "$dst" ]; then
          cp -r "$src" "$dst"
        fi
      }

      relink() {
        src="$1"
        dst="$2"

        mkdir -p "$(dirname "$dst")"
        if [ -L "$dst" ] || [ -e "$dst" ]; then
          rm -f "$dst"
        fi
        ln -s "$src" "$dst"
      }

      ${optionalString (cfg.compositor == "niri") ''
        NIRI_SRC="${selectedNiriConfig}"
        NIRI_DST="${config.xdg.configHome}/niri"
        VARIANT="${cfg.variant}"

        mkdir -p "$NIRI_DST"

        # Copy config file with variant suffix
        copy_if_missing_file "$NIRI_SRC/config.kdl" "$NIRI_DST/config.$VARIANT.kdl"

        # Copy variant-specific content (files + directories)
        copy_if_missing_dir "$NIRI_SRC/$VARIANT" "$NIRI_DST/$VARIANT"

        # Re-create active niri config symlink when switching variant
        relink "$NIRI_DST/config.$VARIANT.kdl" "$NIRI_DST/config.kdl"
      ''}

      ${optionalString (cfg.compositor == "hyprland") ''
        HYPR_SRC="${selectedHyprlandConfig}"
        HYPR_DST="${config.xdg.configHome}/hypr"
        VARIANT="${cfg.variant}"

        mkdir -p "$HYPR_DST"

        # Copy config file with variant suffix
        copy_if_missing_file "$HYPR_SRC/hyprland.conf" "$HYPR_DST/hyprland.$VARIANT.conf"

        # Copy variant-specific content (files + directories)
        copy_if_missing_dir "$HYPR_SRC/$VARIANT" "$HYPR_DST/$VARIANT"

        # Re-create active hyprland config symlink when switching variant
        relink "$HYPR_DST/hyprland.$VARIANT.conf" "$HYPR_DST/hyprland.conf"
      ''}

      ${optionalString (cfg.variant == "dms") ''
        copy_if_missing_dir "${defaultDmsConfig}" "${config.xdg.configHome}/DankMaterialShell"
      ''}

      ${optionalString (cfg.variant == "noctalia") ''
        copy_if_missing_dir "${defaultNoctaliaConfig}" "${config.xdg.configHome}/noctalia"
      ''}
    '';
  };
}
