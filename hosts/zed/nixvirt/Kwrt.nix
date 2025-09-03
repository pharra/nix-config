{
  lib,
  pkgs,
  config,
  NixVirt,
  ...
} @ args: let
  base = import ../../../nixos/nixvirt/base.nix args;
  linux_template = base.linux_template;
  pci_address = base.pci_address;
  usb_address = base.usb_address;
  drive_address = base.drive_address;
in {
  definition = let
    Kwrt = linux_template {
      name = "Kwrt";
      uuid = "ee43005c-2e7b-4af2-bfae-8c52eeb22697";
      memory = {
        count = 1;
        unit = "GiB";
      };
      storage_vol = /home/wf/Data/openwrt/Kwrt.qcow2;
      # install_vol = {
      #   pool = "ISOPool";
      #   volume = "archlinux-2024.04.01-x86_64.iso";
      # };
      nvram_path = /home/wf/Data/RAMPool/Kwrt.fd;
      no_graphics = true;
    };
  in
    NixVirt.lib.domain.writeXML (
      Kwrt
      // {
        cpu = {
          mode = "host-passthrough";
          check = "none";
          migratable = true;
          topology = {
            sockets = 1;
            dies = 1;
            cores = 2;
            threads = 2;
          };
        };
        devices =
          Kwrt.devices
          // {
            interface = {
              type = "bridge";
              model = {type = "virtio";};
              source = {bridge = "br0";};
            };
          };
      }
    );
  active = false;
}
