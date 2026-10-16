# 休眠模块：当前没有任何配置引用它（因此里面的 age 秘密也不会被解密）。
{
  config,
  lib,
  pkgs,
  mysecrets,
  ...
}:
with lib; let
  cfg = config.services.pharra.tailscale;
in {
  options = {
    services.pharra.tailscale = {
      enable = mkEnableOption "tailscale VPN";

      advertiseRoutes = mkOption {
        type = types.listOf types.str;
        default = ["192.168.254.0/24"];
        description = "广播到 tailnet 的子网（--advertise-routes，逗号分隔）";
      };

      advertiseExitNode = mkOption {
        type = types.bool;
        default = true;
        description = "是否把本机作为 exit node 广播";
      };

      derper = {
        domain = mkOption {
          type = types.str;
          default = "tailscale.int4byte.com";
          description = "自建 DERP 的域名";
        };
        port = mkOption {
          description = "DERP 服务端口";
          type = types.port;
          default = 22079;
        };
        stunPort = mkOption {
          description = "DERP 的 STUN 端口";
          type = types.port;
          default = 3478;
        };
      };
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
      extraUpFlags =
        optional cfg.advertiseExitNode "--advertise-exit-node"
        ++ ["--accept-routes=true" "--accept-dns=true"]
        ++ optional (cfg.advertiseRoutes != []) "--advertise-routes=${concatStringsSep "," cfg.advertiseRoutes}";
      derper = {
        enable = true;
        domain = cfg.derper.domain;
        port = cfg.derper.port;
        stunPort = cfg.derper.stunPort;
        configureNginx = false;
      };
    };
  };
}
