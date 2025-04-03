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
    Linux = linux_template {
      name = "Linux";
      uuid = "ee43005c-2e7b-4af2-bfae-8c52eeb22672";
      memory = {
        count = 8;
        unit = "GiB";
      };
      storage_vol = {
        pool = "DiskPool";
        volume = "Linux.qcow2";
      };
      # install_vol = {
      #   pool = "ISOPool";
      #   volume = "archlinux-2025.04.01-x86_64.iso";
      # };
      nvram_path = /home/wf/Data/RAMPool/Linux.fd;
      no_graphics = true;
    };
  in
    NixVirt.lib.domain.writeXML (
      Linux
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
          feature = {
            policy = "require";
            name = "topoext";
          };
        };
        devices =
          Linux.devices
          // {
            graphics = {
              type = "spice";
              autoport = true;
              listen = {type = "address";};
              image = {compression = false;};
              gl = {enable = false;};
            };
            hostdev = [
              {
                type = "pci";
                mode = "subsystem";
                managed = true;
                # GTX 1650 Super 02:00.0
                source = {address = pci_address 2 0 0;};
                address = pci_address 5 0 0 // {multifunction = true;};
              }
              {
                type = "pci";
                mode = "subsystem";
                managed = true;
                source = {address = pci_address 2 0 1;};
                # GTX 1650 Super 02:00.1
                address = pci_address 5 0 1 // {multifunction = true;};
              }
              {
                type = "pci";
                mode = "subsystem";
                managed = true;
                # GTX 1650 Super 02:00.2
                source = {address = pci_address 2 0 2;};
                address = pci_address 5 0 2 // {multifunction = true;};
              }
              {
                type = "pci";
                mode = "subsystem";
                managed = true;
                source = {address = pci_address 2 0 3;};
                # GTX 1650 Super 02:00.3
                address = pci_address 5 0 3 // {multifunction = true;};
              }
              {
                type = "pci";
                mode = "subsystem";
                managed = true;
                source = {address = pci_address 3 0 2;};
                # MLX 5 03:00.2
                address = pci_address 7 0 0;
              }
              {
                type = "usb";
                mode = "subsystem";
                source = [
                  {
                    vendor = [{id = lib.trivial.fromHexString "0x046d";}];
                    product = [{id = lib.trivial.fromHexString "0xc53f";}];
                  }
                ];
                # Mouse
              }
              {
                type = "usb";
                mode = "subsystem";
                source = [
                  {
                    vendor = [{id = lib.trivial.fromHexString "0x05ac";}];
                    product = [{id = lib.trivial.fromHexString "0x0256";}];
                  }
                ];
                # Keyboard
              }
            ];
            interface = [
              {
                type = "bridge";
                model = {type = "virtio";};
                source = {bridge = "br0";};
              }
            ];
          };
      }
    );
  active = null;
}
