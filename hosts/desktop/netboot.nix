{
  config,
  lib,
  pkgs,
  ...
}: {
  boot.iscsi-initiator = {
    name = "iqn.2023-11.org.nixos:desktop";
    discoverPortal = "homelab.intern";
    target = "iqn.2016-06.io.spdk:nixos";
  };

  boot.initrd = {
    # support dns resolv in initrd
    extraUtilsCommands = ''
      cp -pv ${pkgs.glibc.out}/lib/libnss_dns.so.* $out/lib
      cp -pv ${pkgs.glibc.out}/lib/libresolv.so.* $out/lib
    '';
    network = {
      enable = true;
      udhcpc.enable = true;
    };
  };
}
