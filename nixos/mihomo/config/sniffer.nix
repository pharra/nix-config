{...}: {
  services.mihomo.config.sniffer = {
    enable = true;
    sniff = {
      HTTP = {
        ports = [80 "8080-8880"];
        override-destination = true;
      };
      TLS = {
        ports = [443 8443];
      };
      QUIC = {
        ports = [443 8443];
      };
    };
    skip-domain = [
      "Mijia Cloud"
      "+.push.apple.com"
    ];
  };
}
