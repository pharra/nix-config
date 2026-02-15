{
  config,
  lib,
  pkgs,
  utils,
  mysecrets,
  ...
}:
with lib; let
  cfg = config.services.pharra.caddy;
in {
  options = {
    services.pharra.caddy = {
      enable = mkEnableOption "Caddy web server";
    };
  };

  config = mkIf cfg.enable {
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
        hash = "sha256-SrAHzXhaT3XO3jypulUvlVHq8oiLVYmH3ibh3W3aXAs=";
      };
      configFile = config.age.secrets.caddy_homelab_conf.path;
    };

    networking.firewall = {
      allowedTCPPorts = [8443];
    };
  };
}
