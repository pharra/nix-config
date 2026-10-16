# build 变体（配置名 <host>_<build>）的唯一真源。
# 新增变体 = 在这里补两项（NixOS 侧开关 + home 侧开关）；
# 漏了会在 eval 期直接报错，而不是静默退化成 base。
{lib}: let
  # NixOS 侧：变体 -> services.pharra.* 配置
  nixos = {
    base = {services.pharra.base.enable = true;};
    kde = {services.pharra.kde.enable = true;};
    gnome = {services.pharra.gnome.enable = true;};
    cosmic = {services.pharra.cosmic.enable = true;};
    denial = {services.pharra.denial.enable = true;};
    wm = {
      services.pharra.desktopShell = {
        enable = true;
        variant = "noctalia";
      };
    };
  };

  # home 侧：变体 -> home.pharra 下额外要打开的开关
  homeSwitch = {
    base = {};
    kde = {kde.enable = true;};
    gnome = {gnome.enable = true;};
    cosmic = {cosmic.enable = true;};
    denial = {denial.enable = true;};
    wm = {desktopShell.enable = true;};
  };

  # 所有变体共有的 home 基础开关（对应原来的 home/base.nix）
  baseHome = {base.enable = true;};
  # 非 base 变体额外打开的桌面开关
  desktopHome = {
    desktop.enable = true;
    input-method.enable = true;
  };

  names = builtins.attrNames nixos;
in
  assert builtins.attrNames nixos == builtins.attrNames homeSwitch; rec {
    inherit names;

    # 变体对应的 NixOS 模块
    nixosModule = variant:
      if builtins.elem variant names
      then nixos.${variant}
      else throw "未知的 build 变体 '${variant}'，可用变体：${builtins.concatStringsSep ", " names}";

    # 变体对应的 Home Manager 模块（取代原来 6 个 home/<variant>.nix）
    mkHomeModule = username: variant:
      if builtins.elem variant names
      then {
        home.pharra =
          baseHome
          // lib.optionalAttrs (variant != "base") desktopHome
          // homeSwitch.${variant};

        home = {
          inherit username;
          homeDirectory = "/home/${username}";

          # This value determines the Home Manager release that your
          # configuration is compatible with. This helps avoid breakage
          # when a new Home Manager release introduces backwards
          # incompatible changes.
          #
          # You can update Home Manager without changing this value. See
          # the Home Manager release notes for a list of state version
          # changes in each release.
          stateVersion = "26.05";
        };

        # Let Home Manager install and manage itself.
        programs.home-manager.enable = true;
      }
      else throw "未知的 build 变体 '${variant}'，可用变体：${builtins.concatStringsSep ", " names}";
  }
