# build 变体（配置名 <host>_<build>）的唯一真源。
# 每个 variant 现在就是一个 NixOS 模块：系统配置和 hjem 用户配置写在同一个
# modules/desktop/<name>/default.nix 里；新增变体只需在下面加一条。
{lib}: let
  nixos = {
    base = {services.pharra.no-desktop.enable = true;};
    kde = {services.pharra.kde.enable = true;};
    cosmic = {services.pharra.cosmic.enable = true;};
    denial = {services.pharra.denial.enable = true;};
    wm = {
      services.pharra.desktop-shell = {
        enable = true;
        variant = "noctalia";
      };
    };
  };

  names = builtins.attrNames nixos;
in rec {
  inherit names;

  # 变体对应的 NixOS 模块（系统 + hjem 用户配置）
  nixosModule = variant:
    if builtins.elem variant names
    then nixos.${variant}
    else throw "未知的 build 变体 '${variant}'，可用变体：${lib.concatStringsSep ", " names}";
}
