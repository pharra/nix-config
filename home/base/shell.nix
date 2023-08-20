{
  config,
  pkgs,
  ...
}: let
  d = config.xdg.dataHome;
  c = config.xdg.configHome;
  cache = config.xdg.cacheHome;
in rec {
  # add environment variables
  systemd.user.sessionVariables = {
    # set default applications
    TERM = "xterm-256color";

    # enable scrolling in git diff
    DELTA_PAGER = "less -R";

    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
  };

  programs.bash = {
    # load the alias file for work
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv = {enable = true;};
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    enableVteIntegration = true;
    history = {
      share = true;
      size = 1048576;
    };
    autocd = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "docker"
        "git"
        "golang"
        "fd"
        "systemd"
        "git-auto-fetch"
        "history-substring-search"
      ];
      theme = "robbyrussell";
    };

    plugins = [
      {
        name = "zsh-nix-shell";
        file = "nix-shell.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "chisui";
          repo = "zsh-nix-shell";
          rev = "v0.5.0";
          sha256 = "0za4aiwwrlawnia4f29msk822rj9bgcygw6a8a6iikiwzjjz0g91";
        };
      }
      {
        name = "zsh-syntax-highlighting";
        file = "zsh-syntax-highlighting.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-syntax-highlighting";
          rev = "c5ce0014677a0f69a10b676b6038ad127f40c6b1";
          sha256 = "000ksv6bb4qkdzp6fdgz8z126pwin6ywib5d6cfwqa2w27xqm9sj";
        };
      }
    ];

    initExtra = ''
      # config of zsh-users/zsh-syntax-highlighting
      typeset -A ZSH_HIGHLIGHT_STYLES

      bindkey "''${key[Up]}" history-beginning-search-backward
      bindkey "''${key[Down]}" history-beginning-search-forward

      ZSH_HIGHLIGHT_STYLES[comment]='fg=magenta,bold'
      source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
    '';
  };

  home.sessionVariables = systemd.user.sessionVariables;
}
