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
  };
}
