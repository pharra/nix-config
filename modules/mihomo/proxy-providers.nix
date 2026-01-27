{
  lib,
  config,
  ...
}: let
  NodeParam = {
    type = "http";
    interval = 86400;
    health-check = {
      enable = true;
      url = "https://www.gstatic.com/generate_204";
      interval = 300;
    };
  };
in {
  services.mihomo.config.proxy-providers = lib.mkIf config.services.mihomo.enable {
    "Node" =
      NodeParam
      // {
        url = config.sops.placeholder."mihomo/providers/substore";
        path = "./proxy_provider/providers-substore.yaml";
      };
  };

  sops = {
    secrets = lib.mkIf config.services.mihomo.enable (lib.genAttrs [
      "mihomo/providers/substore"
    ] (name: {restartUnits = ["mihomo.service"];}));
  };
}
