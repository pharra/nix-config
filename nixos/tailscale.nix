{
  lib,
  pkgs,
  username,
  config,
  mysecrets,
  ...
}: {
  age.secrets."tailscale_authkey" = {
    file = "${mysecrets}/tailscale_authkey.age";
    mode = "777";
  };

  environment.systemPackages = [
    pkgs.tailscale
  ];

  services.derper = {
    enable = true;
    hostname = "tailscale.inc4byte.work";
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    authKeyFile = config.age.secrets.tailscale_authkey.path;
    extraUpFlags = ["--advertise-exit-node" "--accept-routes=true" "--accept-dns=true"];
  };
}
