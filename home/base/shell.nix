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

  home.sessionVariables = systemd.user.sessionVariables;
}
