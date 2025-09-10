{...}: {
  services.mihomo.config.dns = {
    enable = true;
    prefer-h3 = false;
    ipv6 = false;
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
    respect-rules = true;
    nameserver = [
      "system"
      "https://8.8.8.8/dns-query"
      "https://223.5.5.5/dns-query"
    ];
    proxy-server-nameserver = [
      "https://doh.pub/dns-query"
      "https://dns.alidns.com/dns-query"
    ];
    nameserver-policy = {
      "rule-set:google_domain" = [
        "https://8.8.8.8/dns-query"
      ];
      # "rule-set:cn_domain" = [
      #   "223.5.5.5"
      # ];
      # "rule-set:custom-direct-domain" = [
      #   "119.29.29.29"
      #   "223.5.5.5"
      # ];
    };
  };
}
