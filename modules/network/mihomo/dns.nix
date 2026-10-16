{
  lib,
  config,
  ...
}: {
  networking.nameservers = lib.mkIf config.services.mihomo.enable ["119.29.29.29"];
  services.resolved = lib.mkIf config.services.mihomo.enable {
    settings.Resolve.Domains = ["~."];
  };
  services.mihomo.config.dns = lib.mkIf config.services.mihomo.enable {
    enable = true;
    prefer-h3 = false;
    respect-rules = true;
    ipv6 = false;
    enhanced-mode = "redir-host";
    use-system-hosts = false;
    use-hosts = true;
    default-nameserver = [
      "https://223.5.5.5/dns-query"
    ];
    proxy-server-nameserver = [
      "https://223.5.5.5/dns-query"
    ];
    direct-nameserver = [
      "https://223.5.5.5/dns-query"
    ];
    nameserver = [
      "https://1.1.1.1/dns-query"
    ];
    nameserver-policy = {
      "geosite:cn" = [
        "https://223.5.5.5/dns-query"
      ];
    };
  };
}
