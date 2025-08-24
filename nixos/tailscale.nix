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

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    authKeyFile = config.age.secrets.tailscale_authkey.path;
    extraUpFlags = ["--advertise-exit-node" "--accept-routes=true" "--accept-dns=true"];
    derper = {
      enable = true;
      domain = "tailscale.int4byte.cfd";
      port = 22079;
      stunPort = 3478;
      configureNginx = false;
    };
  };
}
