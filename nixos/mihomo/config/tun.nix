{...}: {
  services.mihomo.config.tun = {
    enable = true;
    stack = "mixed";
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
