{
  lib,
  config,
  ...
}: {
  services.mihomo.config.sniffer = lib.mkIf config.services.mihomo.enable {
    enable = true;
    force-dns-mapping = true;
    parse-pure-ip = true;
    override-destination = true;
    sniff = {
      TLS = {
        ports = [443 8443];
      };
      HTTP = {
        ports = [80 "8080-8880"];
      };
      QUIC = {
        ports = [443 8443];
      };
    };
    force-domain = [
      "+.netflix.com"
      "+.nflxvideo.net"
      "+.amazonaws.com"
      "+.media.dssott.com"
    ];
    skip-domain = [
      "+.apple.com"
      "Mijia Cloud"
      "dlg.io.mi.com"
      "+.oray.com"
      "+.sunlogin.net"
      "geosite:cn"
    ];
  };
}
