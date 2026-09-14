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
  defaultUmbrielConfig = ./umbriel;
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
        type = types.enum ["niri" "umbriel"];
        default = attrByPath ["services" "pharra" "desktopShell" "compositor"] "niri" osConfig;
        description = "The Wayland compositor to use with this desktop shell (niri or umbriel)";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.user.sessionVariables = {
      "NIXOS_OZONE_WL" = "1"; # for any ozone-based browser & electron apps to run on wayland
      "MOZ_ENABLE_WAYLAND" = "1"; # for firefox to run on wayland
      "MOZ_WEBRENDER" = "1";
      # "QS_ICON_THEME" = "Papirus"; # default icon theme for Qt apps (overridable by user)
      # "AQ_DRM_DEVICES" = "/dev/dri/amd-igpu"; # Set the environment variable for AMD iGPU access in Hyprland
    };

    services.xembed-sni-proxy.enable = true;

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

        if [ -d "$dst" ]; then
          chmod -R u+w "$dst"
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
        NIRI_SRC="${defaultNiriConfig}"
        NIRI_DST="${config.xdg.configHome}/niri"

        # Copy variant-specific content (files + directories)
        copy_if_missing_dir "$NIRI_SRC" "$NIRI_DST"
      ''}

      ${optionalString (cfg.compositor == "umbriel") ''
        UMBRIEL_SRC="${defaultUmbrielConfig}"
        UMBRIEL_DST="${config.xdg.configHome}/umbriel"

        # Copy variant-specific content (files + directories)
        copy_if_missing_dir "$UMBRIEL_SRC" "$UMBRIEL_DST"
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
