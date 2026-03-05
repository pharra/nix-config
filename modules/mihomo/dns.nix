{
  lib,
  config,
  ...
}: {
  networking.nameservers = lib.mkIf config.services.mihomo.enable ["119.29.29.29"];
  services.resolved = lib.mkIf config.services.mihomo.enable {
    domains = ["~."];
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
      "119.29.29.29"
    ];
    proxy-server-nameserver = [
      "119.29.29.29"
    ];
    direct-nameserver = [
      "119.29.29.29"
    ];
    nameserver = [
      "119.29.29.29"
    ];
  };
}
