{
  lib,
  config,
  ...
}: {
  networking.nameservers = lib.mkIf config.services.mihomo.enable ["114.114.114.114"];
  services.resolved = lib.mkIf config.services.mihomo.enable {
    domains = ["~."];
  };
  services.mihomo.config.dns = {
    enable = true;
    prefer-h3 = false;
    ipv6 = true;
    enhanced-mode = "redir-host";
    # fake-ip-range = "198.18.0.1/16";
    # fake-ip-filter = [
    #   "+.+m2m"
    #   "+.$injections.adguard.org"
    #   "+.$local.adguard.org"
    #   "+.+bogon"
    #   "+.+lan"
    #   "+.+local"
    #   "+.+localdomain"
    #   "+.home.arpa"
    #   "dns.msftncsi.com"
    #   "*.srv.nintendo.net"
    #   "*.stun.playstation.net"
    #   "xbox.*.microsoft.com"
    #   "*.xboxlive.com"
    #   "*.turn.twilio.com"
    #   "*.stun.twilio.com"
    #   "stun.syncthing.net"
    #   "stun.*"
    #   "*.sslip.io"
    #   "*.nip.io"
    # ];
    nameserver = [
      "https://8.8.8.8/dns-query"
      # "https://223.5.5.5/dns-query"
    ];
    respect-rules = true;
    proxy-server-nameserver = [
      "https://223.5.5.5/dns-query"
    ];
    direct-nameserver = [
      "https://223.5.5.5/dns-query"
    ];
    nameserver-policy = {
      "rule-set:google_domain" = [
        "https://8.8.8.8/dns-query"
      ];
      "rule-set:cn_domain" = [
        "https://223.5.5.5/dns-query"
      ];
      "geosite:cn,apple,private" = [
        "https://223.5.5.5/dns-query"
      ];
    };
  };
}
