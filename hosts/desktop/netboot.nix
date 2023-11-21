{
  config,
  lib,
  pkgs,
  ...
}: {
  boot.iscsi-initiator = {
    name = "iqn.2023-11.org.nixos:desktop";
    discoverPortal = "192.168.29.1:3260";
    target = "iqn.2016-06.io.spdk:nixos";
  };

  boot.initrd.network = {
    enable = true;
    udhcpc.enable = true;
  };
}
