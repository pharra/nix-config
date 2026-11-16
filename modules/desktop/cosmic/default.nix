{
  config,
  lib,
  pkgs,
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
    # 整套 COSMIC 组件、会话包（systemd.packages）和 portal 都交给 nixpkgs 的
    # cosmic 模块，这里只补这个变体自己的开关。
    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;

    services.pharra.waywallen-layer-shell.enable = true;

    environment.systemPackages = with pkgs; [
      wayland-utils # Wayland utilities
      wl-clipboard # Command-line copy/paste utilities for Wayland
    ];

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
