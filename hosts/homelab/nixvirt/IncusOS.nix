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
    IncusOS = linux_template {
      name = "IncusOS";
      uuid = "7936d5bd-d225-49bd-9159-f4659b32ed7e";
      memory = {
        count = 8;
        unit = "GiB";
      };
      # storage_vol = /home/wf/Data/VMPool/IncusOS.qcow2;
      nvram_path = /home/wf/Data/RAMPool/IncusOS.fd;
      # no_graphics = true;
    };
  in
    NixVirt.lib.domain.writeXML (
      IncusOS
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
          IncusOS.devices
          // {
            disk =
              (
                if builtins.isNull IncusOS.devices.disk
                then []
                else IncusOS.devices.disk
              )
              ++ [
                # IncusOS.qcow2
                {
                  type = "file";
                  device = "disk";
                  driver = {
                    name = "qemu";
                    type = "qcow2";
                    cache = "none";
                    discard = "unmap";
                  };
                  source = {
                    file = "/home/wf/Data/VMPool/IncusOS.qcow2";
                  };
                  target = {
                    dev = "sda";
                    bus = "sata";
                  };
                }
                # Data.qcow2
                {
                  type = "file";
                  device = "disk";
                  driver = {
                    name = "qemu";
                    type = "qcow2";
                    cache = "none";
                    discard = "unmap";
                  };
                  source = {
                    file = "/home/wf/Data/VMPool/IncusOS-Data.qcow2";
                  };
                  target = {
                    dev = "sdb";
                    bus = "sata";
                  };
                }
              ];
            interface = [
              {
                type = "bridge";
                model = {type = "virtio";};
                source = {bridge = "br0";};
                mac = {address = "52:54:00:ef:50:0d";};
              }
              {
                type = "bridge";
                model = {type = "virtio";};
                source = {bridge = "br1";};
                mac = {address = "52:54:00:3f:35:2d";};
              }
            ];
          };
      }
    );
  active = false;
}
