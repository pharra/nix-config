# 用户侧设置：登录 shell、zsh 及插件、以及用户相关的杂项（原 default.nix 的后半段）。
# 与 default.nix 共用同一个开关 services.pharra.common.enable（没有新增开关）。
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.pharra.common;
in {
  config = mkIf cfg.enable {
    # add user's shell into /etc/shells
    environment.shells = with pkgs; [
      bash
      zsh
    ];
    # set user's default shell system-wide
    users.defaultUserShell = pkgs.zsh;
    # zsh configuration
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      vteIntegration = true;
      histSize = 1048576;
      syntaxHighlighting.enable = true;

      ohMyZsh = {
        enable = true;
        plugins = [
          "docker"
          "git"
          "golang"
          "systemd"
          "git-auto-fetch"
          "history-substring-search"
        ];
        theme = "candy";
      };
    };

    # for power management
    # services.upower.enable = true;
    # powerManagement.enable = true;

    # Enable vscode server
    programs.nix-ld.enable = true;
  };
}
