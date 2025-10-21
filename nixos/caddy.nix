{
  pkgs,
  lib,
  config,
  utils,
  inputs,
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
      plugins = ["github.com/caddy-dns/cloudflare@v0.2.1"];
      hash = "sha256-XwZ0Hkeh2FpQL/fInaSq+/3rCLmQRVvwBM0Y1G1FZNU=";
    };
    configFile = config.age.secrets.caddy_homelab_conf.path;
  };

  networking.firewall = {
    allowedTCPPorts = [8443];
  };
}
