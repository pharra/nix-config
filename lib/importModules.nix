# 模块自动发现：把 dir 下的模块目录导入，返回 { <模块名> = <模块>; }。
#
# 目录布局：<dir>/<name>/default.nix，或 <dir>/<group>/<name>/default.nix（允许一层分组）。
#
# 顺序规则：**只按模块名排序，与它属于哪个分组无关**。
# 这条规则很重要：NixOS 的 list 型选项（environment.systemPackages 等）按模块顺序合并，
# 所以"把模块在分组之间搬家"不应该改变 drvPath。历史上顺序取决于目录名，改个目录名就会
# 让 18/24 个配置的 drvPath 变化（语义等价，但噪音很大）。
#
# 停用模块：写进 disabled（替代以前"注释掉注册行"的做法）。
# 确实需要指定顺序时用 order（必须是已发现模块的子集）。
{
  dir,
  disabled ? [],
  order ? null,
}: let
  # 递归收集模块目录，depth = 允许向下钻几层（1 = 允许一层分组）
  scan = path: depth: let
    entries = builtins.readDir path;
    names = builtins.attrNames entries;
    isDir = n: (entries.${n} or null) == "directory";
    isModule = n: isDir n && builtins.pathExists (path + "/${n}/default.nix");
    dirs = builtins.filter isDir names;
    direct = map (n: {
      name = n;
      path = path + "/${n}";
    }) (builtins.filter isModule dirs);
    nested =
      builtins.concatLists
      (map (g:
        if depth <= 0
        then []
        else scan (path + "/${g}") (depth - 1))
      (builtins.filter (n: !isModule n) dirs));
  in
    direct ++ nested;

  found = scan dir 1;
  allNames = map (m: m.name) found;
  duplicates = builtins.filter (n: builtins.length (builtins.filter (x: x == n) allNames) > 1) allNames;

  # 顺序：只按模块名，与分组无关
  ordered = builtins.sort (a: b: a.name < b.name) found;
  enabled = builtins.filter (m: !builtins.elem m.name disabled) ordered;
  names = map (m: m.name) enabled;

  unknownDisabled = builtins.filter (n: !(builtins.elem n allNames)) disabled;
  invalidOrder = builtins.filter (n: !(builtins.elem n names)) (
    if order == null
    then []
    else order
  );
  picked =
    if order == null
    then enabled
    else map (n: builtins.head (builtins.filter (m: m.name == n) enabled)) order;
in
  if duplicates != []
  then throw "importModules(${toString dir}): 模块重名：${builtins.concatStringsSep ", " duplicates}"
  else if unknownDisabled != []
  then throw "importModules(${toString dir}): disabled 里有不存在的模块：${builtins.concatStringsSep ", " unknownDisabled}"
  else if invalidOrder != []
  then throw "importModules(${toString dir}): order 里有未发现或被停用的模块：${builtins.concatStringsSep ", " invalidOrder}"
  else
    builtins.listToAttrs (map (m: {
        name = m.name;
        value = import m.path;
      })
      picked)
