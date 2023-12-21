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
    xrayConfigFile=/etc/xray.json
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
