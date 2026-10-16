# 模块目录自动发现：把 dir 下所有含 default.nix 的子目录当作模块导入。
# 返回 { <目录名> = <模块>; }；Nix 的 attrset 本身按属性名排序，所以顺序稳定（目录名字典序）。
#
# 停用某个模块：写进 disabled（替代以前“注释掉注册行”的做法，停用原因会留在代码里）。
# 若某个目录的相对顺序对 list 型选项有影响，可用 order 显式指定（必须是已发现模块的子集）。
{
  dir,
  disabled ? [],
  order ? null,
}: let
  entries = builtins.readDir dir;
  allNames = builtins.attrNames entries;
  isModuleDir = name: (entries.${name} or null) == "directory" && builtins.pathExists (dir + "/${name}/default.nix");
  discovered = builtins.filter isModuleDir allNames;
  enabled = builtins.filter (name: !builtins.elem name disabled) discovered;
  names =
    if order == null
    then enabled
    else order;
  unknownDisabled = builtins.filter (name: !builtins.elem name discovered) disabled;
  invalidOrder = builtins.filter (name: !builtins.elem name enabled) names;
in
  if unknownDisabled != []
  then throw "importModules(${toString dir}): disabled 里有不存在的模块目录：${builtins.concatStringsSep ", " unknownDisabled}"
  else if invalidOrder != []
  then throw "importModules(${toString dir}): order 里有未发现或被停用的模块：${builtins.concatStringsSep ", " invalidOrder}"
  else
    builtins.listToAttrs (map (name: {
        inherit name;
        value = import (dir + "/${name}");
      })
      names)
