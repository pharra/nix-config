{
  config,
  pkgs,
  domain,
  mysecrets,
  ...
} @ args: {
  system.activationScripts."replace_domain" = ''
    domain=${domain}
    caddyConfigFile=${config.age.secrets.caddy_server_conf.path}
    hysteriaConfigFile=${config.age.secrets.hysteria_server_conf.path}
    singboxConfigFile=${config.age.secrets.singbox_server_conf.path}
    xrayConfigFile=/etc/xray_server_conf.json
    ${pkgs.gnused}/bin/sed -i "s/_domain/$domain/g" "$caddyConfigFile"
    ${pkgs.gnused}/bin/sed -i "s/_domain/$domain/g" "$xrayConfigFile"
    ${pkgs.gnused}/bin/sed -i "s/_domain/$domain/g" "$hysteriaConfigFile"
    ${pkgs.gnused}/bin/sed -i "s/_domain/$domain/g" "$singboxConfigFile"
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

  age.secrets."hysteria_server_conf" = {
    file = "${mysecrets}/hysteria_server_conf.age";
    mode = "777";
    path = "/etc/hysteria_server_conf.yaml";
  };

  age.secrets."singbox_server_conf" = {
    file = "${mysecrets}/singbox_server_conf.age";
    mode = "777";
    path = "/etc/singbox_server_conf.json";
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
    hysteria = {
      enable = false;
      settingsFile = config.age.secrets.hysteria_server_conf.path;
      user = "caddy";
      group = "caddy";
    };
    singbox = {
      enable = false;
      settingsFile = config.age.secrets.singbox_server_conf.path;
      user = "caddy";
      group = "caddy";
    };
  };
}
