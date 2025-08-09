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
        count = 32;
        unit = "GiB";
      };
      storage_vol = /fluent/DiskPool/Linux.qcow2;
      install_vol = /fluent/ISOPool/installer.iso;
      nvram_path = /fluent/RAMPool/Linux.fd;
      no_graphics = true;
    };
  in
    NixVirt.lib.domain.writeXML (
      Linux
      // {
        vcpu = {
          placement = "static";
          count = 16;
        };
        cpu = {
          mode = "host-passthrough";
          check = "none";
          migratable = false;
          topology = {
            sockets = 1;
            dies = 1;
            cores = 8;
            threads = 2;
          };
          # cache = {
          #   mode = "passthrough";
          # };
          feature = [
            {
              policy = "require";
              name = "topoext";
            }
          ];
        };
        iothreads = {
          count = 1;
        };
        cputune = {
          vcpupin =
            builtins.map (x: {
              vcpu = x;
              cpuset = toString x;
            }) (lib.lists.range 0 5)
            ++ builtins.map (x: {
              vcpu = x;
              cpuset = toString (x + 8);
            }) (lib.lists.range 8 13);

          emulatorpin = {
            cpuset = "0,16";
          };
          iothreadpin = {
            iothread = 1;
            cpuset = "0,16";
          };
        };
        # memoryBacking = {
        #   hugepages = {};
        # };
        os =
          Linux.os
          // {
            boot = null;
            bootmenu = {enable = true;};
            smbios = {
              mode = "host";
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
                # RTX 4090 01:00.0
                source = {address = pci_address 1 0 0;};
                address = pci_address 5 0 0 // {multifunction = true;};
              }
              {
                type = "pci";
                mode = "subsystem";
                managed = true;
                source = {address = pci_address 1 0 1;};
                # RTX 4090 01:00.1
                address = pci_address 5 0 1 // {multifunction = true;};
              }
              {
                type = "pci";
                mode = "subsystem";
                managed = true;
                source = {address = pci_address 3 0 1;};
                # MLX 5 02:00.1
                address = pci_address 7 0 0;
              }
              {
                type = "pci";
                mode = "subsystem";
                managed = true;
                source = {address = pci_address 6 0 3;};
                # Backend USB Controller 06:00.3
                address = pci_address 9 0 0;
              }
              # {
              #   type = "usb";
              #   mode = "subsystem";
              #   source = [
              #     {
              #       vendor = [{id = lib.trivial.fromHexString "0x046d";}];
              #       product = [{id = lib.trivial.fromHexString "0xc53f";}];
              #     }
              #   ];
              #   # Mouse
              # }
              # {
              #   type = "usb";
              #   mode = "subsystem";
              #   source = [
              #     {
              #       vendor = [{id = lib.trivial.fromHexString "0x05ac";}];
              #       product = [{id = lib.trivial.fromHexString "0x0256";}];
              #     }
              #   ];
              #   # Keyboard
              # }
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
  active = false;
}
