# 休眠模块：当前没有任何 home 配置启用 home.pharra.autostart。
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.home.pharra.autostart;
in {
  options = {
    home.pharra.autostart = {
      enable = mkOption {
        default = false;
        description = ''
          Whether to auto start program.
        '';
      };
      programs = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [];
        description = ''
          auto start programs
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.file = builtins.listToAttrs (map
      (program: let
        pname = program.name;
        pkg = program.pkg;
      in {
        name = ".config/autostart/" + pname + ".desktop";
        value =
          if pkg ? desktopItem
          then {
            # Application has a desktopItem entry.
            # Assume that it was made with makeDesktopEntry, which exposes a
            # text attribute with the contents of the .desktop file
            text = pkg.desktopItem.text;
          }
          else {
            # Application does *not* have a desktopItem entry. Try to find a
            # matching .desktop name in /share/apaplications
            source = pkg + "/share/applications/" + pname + ".desktop";
          };
      })
      cfg.programs);
  };
}
