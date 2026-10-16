# dnsmasq 配置文件的 key=value 渲染（原 default.nix 里的一段 let）。
{
  lib,
  pkgs,
}: let
  formatKeyValue = name: value:
    if value == true
    then name
    else if value == false
    then "# setting `${name}` explicitly set to false"
    else lib.generators.mkKeyValueDefault {} "=" name value;

  settingsFormat = pkgs.formats.keyValue {
    mkKeyValue = formatKeyValue;
    listsAsDuplicateKeys = true;
  };
in {
  inherit formatKeyValue settingsFormat;
}
