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

    programs.denial.uiDevelopment.enable = true;
    # 从 fork / 私有 checkout 构建时必须指定，否则 ui setup 会去官方仓库找这个 commit：
    programs.denial.uiDevelopment.sourceRemote = "https://github.com/pharra/denial.git";

    programs = {
      dux-files = {
        enable = true;
        systemd.enable = false;
        portal.enable = true;
      };
    };

    services.displayManager.gdm.enable = true;
    services.displayManager.defaultSession = "denial";

    services.pharra.waywallen-layer-shell.enable = true;

    xdg.portal.config = {
      # 值必须是 portal 实现名（.portal 文件名），不是桌面名。
      "denial" = {
        "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
      };
      "denial" = {
        "org.freedesktop.portal.Secret" = ["gnome-keyring"];
      };
    };

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
