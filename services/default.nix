# 容器服务清单（显式）：一行一项，由 hosts/homelab 导入。
{...}: {
  imports = builtins.attrValues {
    bilisync = import ./bilisync;
    caddy = import ./caddy;
    clouddrive2 = import ./clouddrive2;
    cookiecloud = import ./cookiecloud;
    emby = import ./emby;
    immich = import ./immich;
    magnet = import ./magnet;
    mybili = import ./mybili;
    reader = import ./reader;
    substore = import ./substore;
    xray = import ./xray;
  };
}
