{
  config,
  lib,
  pkgs,
  mysecrets,
  # 域名：azure/azure_arm 是"一份配置、多个实例"，域名由各实例提供（默认读 /root/domain）；
  # 也可以通过 hosts/machines.nix 的 specialArgs.domain 把某个实例钉死；
  # 留空则回退到手工文件 /root/domain —— 填上之后就不再需要那个文件。
  domain ? "",
  ...
}: let
  domainLine =
    if domain != ""
    then "domain=${lib.escapeShellArg domain}"
    else ''domain=`${pkgs.coreutils-full}/bin/cat /root/domain || echo "default.domain"`'';
in {
  system.activationScripts."replace_domain" = ''
    ${domainLine}
    caddyConfigFile=${config.age.secrets.caddy_server_conf.path}
    xrayConfigFile=${config.age.secrets.xray_server_conf.path}
    ${pkgs.gnused}/bin/sed -i "s/_domain/$domain/g" "$caddyConfigFile"
    ${pkgs.gnused}/bin/sed -i "s/_domain/$domain/g" "$xrayConfigFile"
    # sed -i 是"写新文件再改名"，会把 caddy 秘密重建成 root 所有；caddy 以 caddy 用户运行，这里恢复属主与权限。
    ${pkgs.coreutils-full}/bin/chown caddy:caddy "$caddyConfigFile"
    ${pkgs.coreutils-full}/bin/chmod 0400 "$caddyConfigFile"
  '';

  # Used only by NixOS Modules
  age.secrets."caddy_server_conf" = {
    file = "${mysecrets}/caddy_server_conf.age";
    owner = "caddy";
    mode = "0400";
  };

  age.secrets."xray_server_conf" = {
    file = "${mysecrets}/xray_server_conf.age";
    mode = "0400";
    path = "/etc/xray_server_conf.json";
  };

  services = {
    caddy = {
      enable = true;
      configFile = config.age.secrets.caddy_server_conf.path;
    };
    xray = {
      enable = true;
      settingsFile = config.age.secrets.xray_server_conf.path;
    };
  };
}
