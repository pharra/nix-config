{
  lib,
  pkgs,
  config,
  libs,
  interface,
  ...
}: {
  environment.systemPackages = with pkgs; [
    ipxe
  ];

  services.dnsmasq = {
    enable = true;
    settings = {
      interface = "${interface}";
      enable-tftp = true;
      dhcp-range = "192.168.30.50,192.168.30.150";
      listen-address = "192.168.30.1";
      bind-interfaces = true;
      log-dhcp = true;
      tftp-root = "${pkgs.ipxe}";
      dhcp-match = "set:ipxe,175";
      dhcp-boot = ["tag:!ipxe,ipxe.efi" "tag:ipxe,http://ipxe.local/ipxe/menu.ipxe"];
    };
  };
}
