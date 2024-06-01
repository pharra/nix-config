{
  lib,
  pkgs,
  config,
  NixVirt,
  ...
} @ args: let
  base = import ./base.nix args;
  linux_template = base.linux_template;
  pci_address = base.pci_address;
  usb_address = base.usb_address;
  drive_address = base.drive_address;
in {
  definition = let
    NixOS = linux_template {
      name = "NixOS";
      uuid = "ee43005c-2e7b-4af2-bfae-8c52eeb22673";
      memory = {
        count = 6;
        unit = "GiB";
      };
      storage_vol = {
        pool = "VMPool";
        volume = "NixOS.qcow2";
      };
      nvram_path = /home/wf/Data/RAMPool/NixOS.fd;
      no_graphics = true;
    };
  in
    NixVirt.lib.domain.writeXML (
      NixOS
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
          NixOS.devices
          // {
            # hostdev = [
            #   {
            #     type = "pci";
            #     mode = "subsystem";
            #     managed = true;
            #     source = {address = pci_address 193 0 0;};
            #     # c1 0 0
            #     address = pci_address 5 0 0 // {multifunction = true;};
            #   }
            #   {
            #     type = "pci";
            #     mode = "subsystem";
            #     managed = true;
            #     source = {address = pci_address 193 0 1;};
            #     # c1 0 1
            #     address = pci_address 5 0 1 // {multifunction = true;};
            #   }
            #   {
            #     type = "pci";
            #     mode = "subsystem";
            #     managed = true;
            #     source = {address = pci_address 4 0 3;};
            #     # c1 0 1
            #     address = pci_address 6 0 0;
            #   }
            #   {
            #     type = "pci";
            #     mode = "subsystem";
            #     managed = true;
            #     source = {address = pci_address 68 0 3;};
            #     # c1 0 1
            #     address = pci_address 7 0 0;
            #   }
            #   {
            #     type = "pci";
            #     mode = "subsystem";
            #     managed = true;
            #     source = {address = pci_address 66 0 1;};
            #     # c1 0 1
            #     address = pci_address 8 0 0;
            #   }
            # ];
            interface = {
              type = "bridge";
              model = {type = "virtio";};
              source = {bridge = "br1";};
            };
          };
        # qemu-override = {
        #   device = {
        #     alias = "hostdev0";
        #     frontend = {
        #       property = {
        #         name = "x-vga";
        #         type = "bool";
        #         value = "true";
        #       };
        #     };
        #   };
        # };
      }
    );
}
