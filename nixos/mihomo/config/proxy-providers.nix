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
    "Node-YiYuan" =
      NodeParam
      // {
        url = config.sops.placeholder."mihomo/providers/yiyuan";
        path = "./proxy_provider/providers-yiyuan.yaml";
        override.additional-prefix = "[YY]";
      };
    "Node-LLG" =
      NodeParam
      // {
        url = config.sops.placeholder."mihomo/providers/llg";
        path = "./proxy_provider/providers-llg.yaml";
        override.additional-prefix = "[LLG]";
      };
    "Node-666" =
      NodeParam
      // {
        url = config.sops.placeholder."mihomo/providers/l666";
        path = "./proxy_provider/providers-666.yaml";
        override.additional-prefix = "[666]";
      };
    "Node-paofu" =
      NodeParam
      // {
        url = config.sops.placeholder."mihomo/providers/paofu";
        path = "./proxy_provider/providers-paofu.yaml";
        override.additional-prefix = "[泡芙]";
      };
  };
}
