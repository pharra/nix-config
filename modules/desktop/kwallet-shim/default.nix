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

    # Secret Service：统一用 gnome-keyring。
    # KDE 变体禁用 kwallet 后用它；wm 变体没有桌面栈，靠这里补上。
    # Chromium 系（Edge）的 cookie 加密密钥存在这里 —— 各桌面变体用同一个 keyring 才不会切桌面掉登录。
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;

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
        (config.services.pharra ? dms)
        && config.services.pharra.dms.enable
      ) {
        XDG_CURRENT_DESKTOP = cfg.xdgCurrentDesktop;
        KDE_SESSION_VERSION = "6";
        KDE_FULL_SESSION = "true";
        QT_QPA_PLATFORM = "wayland";
      };

    # Denial 在启动 app launcher 的应用时会硬编码
    # XDG_CURRENT_DESKTOP=Denial；它支持通过 applicationEnvironment
    # 覆盖应用环境。这里把默认环境和 code.desktop 都改成 Denial:KDE，
    # 让 Chromium/Electron 选择 KWallet 后端。
    systemd.user.services.denial-app-environment =
      mkIf (
        (config.services.pharra ? denial)
        && config.services.pharra.denial.enable
      ) {
        wantedBy = ["denial-session.target"];
        after = ["denial-session.target"];
        serviceConfig.Type = "oneshot";
        script = ''
          settings="$HOME/.config/denial/settings.json"
          i=0
          while [ ! -f "$settings" ] && [ "$i" -lt 50 ]; do
            ${pkgs.coreutils}/bin/sleep 0.1
            i=$((i + 1))
          done
          [ -f "$settings" ] || exit 0

          tmp="$(${pkgs.coreutils}/bin/mktemp "$settings".XXXXXX)"
          if ${pkgs.jq}/bin/jq '
            .applicationEnvironment.default["XDG_CURRENT_DESKTOP"] = "Denial:KDE"
            | .applicationEnvironment.default["KDE_SESSION_VERSION"] = "6"
            | .applicationEnvironment.default["KDE_FULL_SESSION"] = "true"
            | .applicationEnvironment.applications["code.desktop"]["XDG_CURRENT_DESKTOP"] = "Denial:KDE"
            | .applicationEnvironment.applications["code.desktop"]["KDE_SESSION_VERSION"] = "6"
            | .applicationEnvironment.applications["code.desktop"]["KDE_FULL_SESSION"] = "true"
          ' "$settings" > "$tmp"; then
            ${pkgs.coreutils}/bin/chmod 600 "$tmp"
            ${pkgs.coreutils}/bin/mv -f "$tmp" "$settings"
          else
            ${pkgs.coreutils}/bin/rm -f "$tmp"
          fi
        '';
        startLimitBurst = 0;
        startLimitIntervalSec = 0;
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
