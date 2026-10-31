{
  config,
  lib,
  pkgs,
  mysecrets,
  # 域名由 hosts/machines.nix 的 specialArgs.domain 传入（每台 azure 主机一个，其余配置相同）；
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
  '';

  # Used only by NixOS Modules
  age.secrets."caddy_server_conf" = {
    file = "${mysecrets}/caddy_server_conf.age";
    mode = "777";
  };

  age.secrets."xray_server_conf" = {
    file = "${mysecrets}/xray_server_conf.age";
    mode = "777";
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
