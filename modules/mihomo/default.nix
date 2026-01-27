{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;
  format = pkgs.formats.yaml {};
  cfg = config.services.mihomo.config;
in {
  imports = [
    ./dns.nix
    ./proxy-groups.nix
    ./proxy-providers.nix
    ./rules.nix
    ./sniffer.nix
    ./tun.nix
  ];

  options.services.mihomo.config = mkOption {
    default = {};
    type = types.submodule {
      freeformType = format.type;
      options = {
        tun = {
          enable = mkOption {
            default = config.services.mihomo.tunMode;
            type = types.bool;
          };
          device = mkOption {
            default = "utun0";
            type = types.str;
          };
        };
      };
    };
  };

  config = {
    networking.firewall.trustedInterfaces = lib.mkIf config.services.mihomo.tunMode [cfg.tun.device];
    sops.templates."mihomo-config.yaml".content = builtins.toJSON cfg;
    services.mihomo.configFile = config.sops.templates."mihomo-config.yaml".path;

    services.mihomo.tunMode = lib.mkIf config.services.mihomo.enable true;

    # 基础 mihomo 配置
    services.mihomo.config = lib.mkIf config.services.mihomo.enable {
      mixed-port = 7154;
      allow-lan = true;
      mode = "rule";
      log-level = "warning";
      ipv6 = true;
      find-process-mode = "strict";
      external-controller = "0.0.0.0:9096";
      unified-delay = true;
      tcp-concurrent = true;
      global-client-fingerprint = "chrome";
      profile = {
        store-selected = true;
        store-fake-ip = true;
      };

      # GEO 数据相关配置
      geodata-mode = true; # GEOIP数据模式，false:mmdb，true:dat
      geodata-loader = "standard"; # GEO文件加载模式
      geo-auto-update = true; # GEO文件自动更新
      geo-update-interval = 24; # 更新间隔，小时
      geox-url = {
        geoip = "https://ghfast.top/https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.dat";
        geosite = "https://ghfast.top/https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat";
        mmdb = "https://ghfast.top/https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country.mmdb";
        asn = "https://ghfast.top/https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/GeoLite2-ASN.mmdb";
      };
    };
  };
}
