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
    services.pharra.alacritty = {
      enable = true;
      opacity = 0.6;
    };

    programs.denial.enable = true;
    programs.denial.plugins.enable = true; # Optional Plugin Manager.

    services.displayManager.gdm.enable = true;
    services.displayManager.defaultSession = "denial";

    services.pharra.kwallet-shim.enable = true;
    services.pharra.kwallet-shim.xdgCurrentDesktop = "Denial:KDE";

    services.pharra.waywallen-layer-shell.enable = true;

    # services.droidloom = {
    #   enable = true;
    #   user = username;
    #   renderNode = "/dev/dri/renderD128";
    #   gpu = "0000:01:00.0";
    #   graphicsBackend = "forwarding";
    # };

    environment.sessionVariables = {
      "NIXOS_OZONE_WL" = "1";
      "MOZ_ENABLE_WAYLAND" = "1";
      "MOZ_WEBRENDER" = "1";
      "QT_QPA_PLATFORM" = "wayland";

      XMODIFIERS = "@im=fcitx";
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
    };
  };
}
