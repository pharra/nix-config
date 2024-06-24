{
  lib,
  pkgs,
  config,
  NixVirt,
  ...
} @ args: let
  base = import ./base.nix args;
  windows_template = base.windows_template;
  pci_address = base.pci_address;
  usb_address = base.usb_address;
  drive_address = base.drive_address;
in {
  definition = let
    Windows = windows_template {
      name = "Windows";
      uuid = "ee43005c-2e7b-4af2-bfae-8c52eeb22678";
      memory = {
        count = 32;
        unit = "GiB";
      };
      nvram_path = /home/wf/Data/RAMPool/Windows.fd;
      no_graphics = true;
      virtio_net = true;
    };
  in
    NixVirt.lib.domain.writeXML (
      Windows
      // {
        vcpu = {
          placement = "static";
          count = 16;
        };
        cpu = {
          mode = "host-passthrough";
          check = "full";
          migratable = true;
          topology = {
            sockets = 1;
            dies = 1;
            cores = 8;
            threads = 2;
          };
          feature = {
            policy = "require";
            name = "topoext";
          };
        };
        iothreads = {
          count = 1;
        };
        cputune = {
          vcpupin = [
            # core 1
            {
              vcpu = 0;
              cpuset = "3";
            }
            {
              vcpu = 1;
              cpuset = "4";
            }
            {
              vcpu = 2;
              cpuset = "5";
            }
            {
              vcpu = 3;
              cpuset = "6";
            }
            {
              vcpu = 4;
              cpuset = "7";
            }
            {
              vcpu = 5;
              cpuset = "8";
            }
            {
              vcpu = 6;
              cpuset = "9";
            }
            {
              vcpu = 7;
              cpuset = "10";
            }

            # core 2
            {
              vcpu = 8;
              cpuset = "19";
            }
            {
              vcpu = 9;
              cpuset = "20";
            }
            {
              vcpu = 10;
              cpuset = "21";
            }
            {
              vcpu = 11;
              cpuset = "22";
            }
            {
              vcpu = 12;
              cpuset = "23";
            }
            {
              vcpu = 13;
              cpuset = "24";
            }
            {
              vcpu = 14;
              cpuset = "25";
            }
            {
              vcpu = 15;
              cpuset = "26";
            }
          ];
          emulatorpin = {
            cpuset = "2,18";
          };
          iothreadpin = {
            iothread = 1;
            cpuset = "2,18";
          };
        };
        memoryBacking = {
          hugepages = {};
        };
        devices =
          Windows.devices
          // {
            tpm = {
              model = "tpm-crb";
              backend = {
                type = "passthrough";
                device = {
                  path = "/dev/tpm0";
                };
              };
            };
            hostdev = [
              {
                type = "pci";
                mode = "subsystem";
                managed = true;
                # RTX 4090 41:00.0
                source = {address = pci_address 65 0 0;};
                address = pci_address 5 0 0 // {multifunction = true;};
              }
              {
                type = "pci";
                mode = "subsystem";
                managed = true;
                source = {address = pci_address 65 0 1;};
                # RTX 4090 41:00.1
                address = pci_address 5 0 1 // {multifunction = true;};
              }
              {
                type = "pci";
                mode = "subsystem";
                managed = true;
                source = {address = pci_address 5 0 3;};
                # USB Controller 05:00.3
                address = pci_address 6 0 0;
              }
              {
                type = "pci";
                mode = "subsystem";
                managed = true;
                source = {address = pci_address 67 0 3;};
                # USB Controller 43:00.3
                address = pci_address 7 0 0;
              }
              {
                type = "pci";
                mode = "subsystem";
                managed = true;
                source = {address = pci_address 3 0 0;};
                # Intel SSD 760p 3:00.0
                address = pci_address 8 0 0;
              }
              {
                type = "pci";
                mode = "subsystem";
                managed = true;
                source = {address = pci_address 1 0 1;};
                # MLX 1:00.1
                address = pci_address 9 0 0;
              }
            ];
            interface = [
              {
                type = "bridge";
                model = {type = "virtio";};
                source = {bridge = "br0";};
              }
              # {
              #   type = "bridge";
              #   model = {type = "virtio";};
              #   source = {bridge = "ib";};
              # }
              # {
              #   type = "bridge";
              #   model = {type = "virtio";};
              #   source = {bridge = "eth";};
              # }
            ];
          };
        qemu-commandline = {
          arg = [
            {value = "-fw_cfg";}
            {value = "opt/ovmf/X-PciMmio64Mb,string=65536";}
          ];
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
