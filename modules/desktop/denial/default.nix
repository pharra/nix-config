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

    services.displayManager.gdm.enable = true;

    services.pharra.kwallet-shim.enable = true;
    services.pharra.kwallet-shim.xdgCurrentDesktop = "denial:KDE";

    xdg.portal.config = {
      # 值必须是 portal 实现名（.portal 文件名），不是桌面名。
      # 只有 gnome-keyring.portal 和 kwallet.portal 实现 Secret；写 "gnome"
      # 会选中不实现 Secret 的 gnome.portal，然后静默回退到 kwallet。
      "gtk" = {
        "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
      };
    };

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
