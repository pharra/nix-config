{
  config,
  lib,
  pkgs,
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
  # sops 的密文是只读的，不能直接 sed。这里在 caddy/xray 启动前把秘密复制到 /run，
  # 在副本上替换域名；sops 重新安装秘密也不会把替换结果冲掉。
  systemd.services.caddy-xray-config = {
    description = "Substitute _domain into caddy/xray configs";
    wantedBy = ["multi-user.target"];
    after = ["sops-install-secrets.service"];
    before = ["caddy.service" "xray.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${domainLine}
      caddyConfigFile=/run/caddy_server_conf
      xrayConfigFile=/run/xray_server_conf.json
      ${pkgs.coreutils}/bin/install -m 0400 -o caddy -g caddy ${config.sops.secrets.caddy_server_conf.path} "$caddyConfigFile"
      ${pkgs.coreutils}/bin/install -m 0400 -o root -g root ${config.sops.secrets.xray_server_conf.path} "$xrayConfigFile"
      ${pkgs.gnused}/bin/sed -i "s/_domain/$domain/g" "$caddyConfigFile"
      ${pkgs.gnused}/bin/sed -i "s/_domain/$domain/g" "$xrayConfigFile"
      ${pkgs.coreutils}/bin/chown caddy:caddy "$caddyConfigFile"
      ${pkgs.coreutils}/bin/chmod 0400 "$caddyConfigFile"
    '';
  };

  sops.secrets."caddy_server_conf" = {
    sopsFile = ./caddy_server_conf;
    format = "binary";
    mode = "0400";
    restartUnits = ["caddy-xray-config.service" "caddy.service"];
  };

  sops.secrets."xray_server_conf" = {
    sopsFile = ./xray_server_conf.json;
    format = "json";
    key = ""; # 整个 JSON 文件，不是某个字段
    mode = "0400";
    restartUnits = ["caddy-xray-config.service" "xray.service"];
  };

  services = {
    caddy = {
      enable = true;
      configFile = "/run/caddy_server_conf";
    };
    xray = {
      enable = true;
      settingsFile = "/run/xray_server_conf.json";
    };
  };
}
