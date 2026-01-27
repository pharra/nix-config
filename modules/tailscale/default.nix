{
  config,
  lib,
  pkgs,
  username,
  mysecrets,
  ...
}:
with lib; let
  cfg = config.services.pharra.tailscale;
in {
  options = {
    services.pharra.tailscale = {
      enable = mkEnableOption "tailscale VPN";
    };
  };

  config = mkIf cfg.enable {
    age.secrets."tailscale_authkey" = {
      file = "${mysecrets}/tailscale_authkey.age";
      mode = "777";
    };

    environment.systemPackages = [
      pkgs.tailscale
    ];

    services.tailscale = {
      enable = true;
      useRoutingFeatures = "both";
      authKeyFile = config.age.secrets.tailscale_authkey.path;
      extraUpFlags = ["--advertise-exit-node" "--accept-routes=true" "--accept-dns=true" "--advertise-routes=192.168.254.0/24"];
      derper = {
        enable = true;
        domain = "tailscale.int4byte.org";
        port = 22079;
        stunPort = 3478;
        configureNginx = false;
      };
    };
  };
}
