{
  lib,
  pkgs,
  config,
  NixVirt,
  ...
} @ args: let
  base = import ../nixvirt/base.nix args;
  linux_template = base.linux_template;
  pci_address = base.pci_address;
  usb_address = base.usb_address;
  drive_address = base.drive_address;

  mac-generator = import ./mac-generator.nix {inherit lib;};
in {
  definition = let
    Kwrt = linux_template {
      name = "Kwrt";
      uuid = "ee43005c-2e7b-4af2-bfae-8c52eeb22697";
      memory = {
        count = 1;
        unit = "GiB";
      };
      storage_vol = "/var/lib/openwrt/openwrt.qcow2";
      # install_vol = {
      #   pool = "ISOPool";
      #   volume = "archlinux-2024.04.01-x86_64.iso";
      # };
      #nvram_path = /var/lib/openwrt/Kwrt.fd;
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
        memoryBacking = {
          access = {
            mode = "shared";
          };
        };
        devices =
          Kwrt.devices
          // {
            disk =
              if builtins.isNull Kwrt.devices.disk
              then []
              else
                Kwrt.devices.disk
                ++ [
                  {
                    type = "file";
                    device = "disk";
                    driver = {
                      name = "qemu";
                      type = "raw";
                      cache = "none";
                    };
                    source = {
                      file = "/var/lib/openwrt/overlay.img";
                    };
                    target = {
                      dev = "vdd";
                      bus = "virtio";
                    };
                  }
                ];
            # filesystem = [
            #   {
            #     type = "mount";
            #     accessmode = "passthrough";
            #     binary = {
            #       path = "${pkgs.virtiofsd}/bin/virtiofsd";
            #       xattr = true;
            #     };
            #     driver = {type = "virtiofs";};
            #     source = {dir = "/var/lib/openwrt/overlay";};
            #     target = {dir = "overlay";};
            #   }
            # ];
            interface = [
              {
                type = "bridge";
                model = {type = "virtio";};
                source = {bridge = "br2";};
                mac = {address = mac-generator.unicast "${config.networking.hostName}-openwrt-lan";};
              }
              {
                type = "bridge";
                model = {type = "virtio";};
                source = {bridge = "br0";};
                mac = {address = mac-generator.unicast "${config.networking.hostName}-openwrt-wan";};
              }
            ];
          };
      }
    );
  active = true;
}
