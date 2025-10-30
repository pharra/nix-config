{
  pkgs,
  lib,
  config,
  utils,
  mysecrets,
  ...
} @ args: {
  age.secrets."caddy_homelab_conf" = {
    file = "${mysecrets}/caddy_homelab_conf.age";
    mode = "777";
    path = "/etc/caddy/caddy_file";
    symlink = false;
  };

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = ["github.com/caddy-dns/cloudflare@v0.2.2"];
      hash = "sha256-4qUWhrv3/8BtNCi48kk4ZvbMckh/cGRL7k+MFvXKbTw=";
    };
    configFile = config.age.secrets.caddy_homelab_conf.path;
  };

  networking.firewall = {
    allowedTCPPorts = [8443];
  };
}
