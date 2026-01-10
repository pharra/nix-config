{
  lib,
  pkgs,
  username,
  config,
  ...
}: {
  services.easytier = {
    enable = true;
    instances = {
      "homelab" = {
        extraSettings = {
          flags = {
            dev_name = "easytier";
          };
          proxy_network = [
            {
              cidr = "192.168.254.0/24";
            }
          ];
        };
        environmentFiles = [
          config.sops.templates."int4byte.env".path
        ];
        settings = {
          ipv4 = "172.0.0.1/24";
          network_name = "int4byte";
          peers = [
            "tcp://public.easytier.cn:11010"
          ];
        };
      };
    };
  };

  sops.templates."int4byte.env".content = ''
    ET_NETWORK_SECRET="${config.sops.placeholder."easytier/int4byte/secret"}"
  '';

  sops = {
    secrets = lib.mkIf config.services.easytier.enable (lib.genAttrs [
      "easytier/int4byte/secret"
    ] (name: {restartUnits = ["easytier-homelab.service"];}));
  };
}
