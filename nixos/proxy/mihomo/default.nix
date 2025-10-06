{...}: {
  imports = [
    ./dns.nix
    ./proxy-groups.nix
    ./proxy-providers.nix
    ./rules.nix
    ./sniffer.nix
    ./tun.nix
  ];

  # See /options/nixos/mihomo.nix
  services.mihomo.config = {
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
}
