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
    FnOS = linux_template {
      name = "FnOS";
      uuid = "ee43005c-2e7b-4af2-bfae-8c52eeb22652";
      memory = {
        count = 8;
        unit = "GiB";
      };
      storage_vol = {
        pool = "VMPool";
        volume = "FnOS.qcow2";
      };
      # install_vol = {
      #   pool = "ISOPool";
      #   volume = "fnos-0.9.29-1142.iso";
      # };
      nvram_path = /home/wf/Data/RAMPool/FnOS.fd;
      no_graphics = true;
    };
  in
    NixVirt.lib.domain.writeXML (
      FnOS
      // {
        vcpu = {
          placement = "static";
          count = 8;
        };
        cpu = {
          mode = "host-passthrough";
          check = "none";
          migratable = true;
          topology = {
            sockets = 1;
            dies = 1;
            cores = 4;
            threads = 2;
          };
        };
        devices =
          FnOS.devices
          // {
            disk =
              if builtins.isNull FnOS.devices.disk
              then []
              else
                FnOS.devices.disk
                ++ [
                  # Games.qcow2
                  {
                    type = "block";
                    device = "disk";
                    driver = {
                      name = "qemu";
                      type = "raw";
                      cache = "none";
                      discard = "unmap";
                    };
                    source = {
                      dev = "/dev/zvol/data/fnos";
                    };
                    target = {
                      dev = "vdd";
                      bus = "virtio";
                    };
                  }
                ];
            interface = [
              {
                type = "bridge";
                model = {type = "virtio";};
                source = {bridge = "br0";};
              }
              {
                type = "bridge";
                model = {type = "virtio";};
                source = {bridge = "br1";};
              }
            ];
          };
      }
    );
  active = true;
}
