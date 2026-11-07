{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib; let
  cfg = config.services.pharra.kwallet-shim;
in {
  options.services.pharra.kwallet-shim = {
    enable = mkEnableOption "KWallet API to Secret Service compatibility shim";
    xdgCurrentDesktop = mkOption {
      type = types.str;
      description = ''
        The value of XDG_CURRENT_DESKTOP to set in the environment.
        This is used to make KWallet API calls from Chromium/Electron/KDE
        applications be redirected to Secret Service (gnome-keyring).
      '';
    };
  };

  config = mkIf cfg.enable {
    # KWallet 只作为 KWallet API -> Secret Service 的兼容层存在：
    # ksecretd 关闭，kwalletd6 把 Chromium/Electron/KDE 的 KWallet 调用转发到
    # gnome-keyring（org.freedesktop.secrets）。
    environment.systemPackages = [pkgs.kdePackages.kwallet];

    environment.sessionVariables = {
      "XDG_CURRENT_DESKTOP" = cfg.xdgCurrentDesktop;
      "KDE_SESSION_VERSION" = "6";
      "KDE_FULL_SESSION" = "true";
    };

    environment.etc."environment.d/10-kwallet-shim.conf".text = ''
      XDG_CURRENT_DESKTOP=${cfg.xdgCurrentDesktop}
      KDE_SESSION_VERSION=6
      KDE_FULL_SESSION=true
    '';

    # DMS 由 systemd 启动，不继承 niri 的 environment 块；统一在模块里给它设置。
    systemd.user.services.dms.environment =
      mkIf (
        (config.services.pharra ? desktop-shell)
        && config.services.pharra.desktop-shell.variant == "dms"
      ) {
        XDG_CURRENT_DESKTOP = cfg.xdgCurrentDesktop;
        KDE_SESSION_VERSION = "6";
        KDE_FULL_SESSION = "true";
        QT_QPA_PLATFORM = "wayland";
      };

    systemd.user.services.noctalia.environment =
      mkIf (
        (config.services.pharra ? desktop-shell)
        && config.services.pharra.desktop-shell.variant == "noctalia"
      ) {
        XDG_CURRENT_DESKTOP = cfg.xdgCurrentDesktop;
        KDE_SESSION_VERSION = "6";
        KDE_FULL_SESSION = "true";
        QT_QPA_PLATFORM = "wayland";
      };

    hjem.extraModules = [
      ({config, ...}:
        mkIf (config.user == username) {
          # kwalletrc 必须允许 KWallet 写回状态，所以不能用 hjem 的 symlink/copy
          # （copy 每次 activation 也会覆盖）。用 user oneshot 只在缺失时创建。
          systemd.services.ensure-kwalletrc = {
            wantedBy = ["default.target"];
            serviceConfig.Type = "oneshot";
            script = ''
              if [ ! -e "$HOME/.config/kwalletrc" ]; then
                ${pkgs.coreutils}/bin/install -Dm644 ${pkgs.writeText "kwalletrc" ''
                [KSecretD]
                Enabled=false

                [Migration]
                MigrateTo3rdParty=false
              ''} "$HOME/.config/kwalletrc"
              fi
            '';
          };
        })
    ];
  };
}
