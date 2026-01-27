{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.home.pharra.base;

  d = config.xdg.dataHome;
  c = config.xdg.configHome;
  cache = config.xdg.cacheHome;
in {
  options = {
    home.pharra.base = {
      enable = mkEnableOption "base home configuration";
    };
  };

  config = mkIf cfg.enable {
    # add environment variables
    systemd.user.sessionVariables = {
      # set default applications
      TERM = "xterm-256color";

      # enable scrolling in git diff
      DELTA_PAGER = "less -R";

      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    };

    home.sessionVariables = config.systemd.user.sessionVariables;

    # Linux Only Packages, not available on Darwin
    home.packages = with pkgs; [
      btop

      # misc
      libnotify
      wireguard-tools # manage wireguard vpn manually, via wg-quick

      # system call monitoring
      strace # system call monitoring
      ltrace # library call monitoring
      lsof # list open files

      # system tools
      sysstat
      lm_sensors # for `sensors` command
      ethtool
      dmidecode # a tool that reads information about your system's hardware from the BIOS according to the SMBIOS/DMI standard
      fio # disk performance

      dnsutils
      screen
      appimage-run
    ];
  };
}
