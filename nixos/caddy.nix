{
  pkgs,
  lib,
  config,
  utils,
  inputs,
  mysecrets,
  ...
} @ args: let
  caddy-custom = pkgs.caddy.override {
    externalPlugins = [
      {
        name = "cloudflare";
        repo = "github.com/caddy-dns/cloudflare";
        version = "737bf003fe8af81814013a01e981dc8faea44c07";
      }
    ];
    vendorHash = "sha256-uyEjAktinJhV3u5xFWAHbBPAX5NZ5utLiCwUVgZVjGw=";
  };
in {
  age.secrets."caddy_homelab_conf" = {
    file = "${mysecrets}/caddy_homelab_conf.age";
    mode = "777";
    path = "/etc/caddy/caddy_file";
    symlink = false;
  };

  services.caddy = {
    enable = true;
    package = caddy-custom;
    configFile = config.age.secrets.caddy_homelab_conf.path;
  };
}
