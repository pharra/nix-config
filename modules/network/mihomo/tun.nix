{
  lib,
  config,
  ...
}: {
  services.mihomo.config.tun = lib.mkIf config.services.mihomo.enable {
    enable = true;
    stack = "system";
    device = "mihomo";
    auto-route = true;
    auto-detect-interface = true;
    dns-hijack = [
      "any:53"
      "tcp://any:53"
    ];
    strict-route = true;
    mtu = 1500;
  };
}
