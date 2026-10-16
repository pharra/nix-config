{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.pharra.easytier;
in {
  options = {
    services.pharra.easytier = {
      enable = mkEnableOption "easytier VPN";

      instanceName = mkOption {
        type = types.str;
        default = "homelab";
        description = "easytier 实例名（决定 systemd 单元名与重启单元）";
      };

      networkName = mkOption {
        type = types.str;
        default = "int4byte";
        description = "easytier 网络名（同时用于 sops 模板与秘密名）";
      };

      ipv4 = mkOption {
        type = types.str;
        default = "172.0.0.1/24";
        description = "本机在虚拟网络里的地址";
      };

      proxyCidr = mkOption {
        type = types.str;
        default = "192.168.254.0/24";
        description = "代理给虚拟网络的网段";
      };

      peers = mkOption {
        type = types.listOf types.str;
        default = ["tcp://public.easytier.cn:11010"];
        description = "中转节点（公共或自建）";
      };
    };
  };

  config = mkIf cfg.enable {
    services.easytier = {
      enable = true;
      instances."${cfg.instanceName}" = {
        extraSettings = {
          flags = {
            dev_name = "easytier";
          };
          proxy_network = [
            {
              cidr = cfg.proxyCidr;
            }
          ];
        };
        environmentFiles = [
          config.sops.templates."${cfg.networkName}.env".path
        ];
        settings = {
          ipv4 = cfg.ipv4;
          network_name = cfg.networkName;
          peers = cfg.peers;
        };
      };
    };

    sops.templates."${cfg.networkName}.env".content = ''
      ET_NETWORK_SECRET="${config.sops.placeholder."easytier/${cfg.networkName}/secret"}"
    '';

    sops = {
      secrets = lib.mkIf config.services.easytier.enable (lib.genAttrs [
        "easytier/${cfg.networkName}/secret"
      ] (name: {restartUnits = ["easytier-${cfg.instanceName}.service"];}));
    };
  };
}
