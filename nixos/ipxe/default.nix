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

  environment.etc = {
    "ipxe/ipxe.efi" = {
      source = pkgs.ipxe + "/ipxe.efi";
    };

    "ipxe/undionly.kpxe" = {
      source = pkgs.ipxe + "/undionly.kpxe";
    };

    "ipxe/boot.ipxe" = {
      source = ./boot.ipxe;
    };
    "ipxe/boot.ipxe.cfg" = {
      source = ./boot.ipxe.cfg;
    };

    "ipxe/menu.ipxe" = {
      source = ./menu.ipxe;
    };

    # "ipxe/wimboot" = {
    #   source = ./wimboot;
    # };
    # "ipxe/boot.wim" = {
    #   source = ./boot.wim;
    # };
    # "ipxe/BCD" = {
    #   source = ./BCD;
    # };
    # "ipxe/boot.sdi" = {
    #   source = ./boot.sdi;
    # };
    # "ipxe/bootmgr" = {
    #   source = ./bootmgr;
    # };
    # "ipxe/bootmgr.efi" = {
    #   source = ./bootmgr.efi;
    # };
    # "ipxe/bootx64.efi" = {
    #   source = ./bootx64.efi;
    # };
  };

  services.dnsmasq = {
    enable = true;
    settings = {
      interface = "${interface.ib},${interface.eth}";
      enable-tftp = true;
      dhcp-range = ["interface:${interface.ib},192.168.30.50,192.168.30.150" "interface:${interface.eth},192.168.29.50,192.168.29.150"];
      listen-address = "192.168.30.1,192.168.29.1";
      bind-interfaces = true;
      log-dhcp = true;
      tftp-root = "/etc/ipxe";
      dhcp-match = "set:ipxe,175";
      dhcp-boot = ["tag:!ipxe,ipxe.efi" "tag:ipxe,boot.ipxe"];
    };
  };
}
