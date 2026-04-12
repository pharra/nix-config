{
  lib,
  pkgs,
  config,
  NixVirt,
  ...
} @ args: let
  base = import ../../../nixos/nixvirt/base.nix args;
  windows_template = base.windows_template;
  pci_address = base.pci_address;
  usb_address = base.usb_address;
  drive_address = base.drive_address;
in {
  definition = let
    Pat = windows_template {
      name = "Pat";
      uuid = "ee43005c-2e7b-4af2-bfae-8c52eeb22679";
      memory = {
        count = 32;
        unit = "GiB";
      };
      nvram_path = /fluent/RAMPool/Pat.fd;
      no_graphics = true;
      virtio_net = true;
      storage_vol = /fluent/DiskPool/Pat.qcow2;
      # install_vol = /fluent/ISOPool/Windows-25H2.iso;
    };
  in
    NixVirt.lib.domain.writeXML (
      Pat
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
            {
              policy = "disable";
              name = "hypervisor";
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
              cpuset = toString (x + 8);
            }) (lib.lists.range 0 7)
            ++ builtins.map (x: {
              vcpu = x;
              cpuset = toString (x + 16);
            }) (lib.lists.range 8 15);

          emulatorpin = {
            cpuset = "0-7,16-23";
          };
          iothreadpin = {
            iothread = 1;
            cpuset = "0-7,16-23";
          };
        };
        memoryBacking = {
          hugepages = {};
        };
        clock =
          Pat.clock
          // {
            timer =
              lib.lists.remove {
                name = "hpet";
                present = false;
              }
              Pat.clock.timer
              ++ [
                {
                  name = "hpet";
                  present = true;
                }
              ];
          };
        os =
          Pat.os
          // {
            boot = null;
            bootmenu = {enable = false;};
            smbios = {
              mode = "host";
            };
          };
        features =
          Pat.features
          // {
            kvm = {
              hidden.state = true;
            };
            hyperv =
              Pat.features.hyperv
              // {
                vendor_id = {
                  state = true;
                  value = "1234567890ab";
                };
              };
          };
        devices =
          Pat.devices
          // {
            # disk =
            #   if builtins.isNull Pat.devices.disk
            #   then []
            #   else
            #     Pat.devices.disk
            #     ++ [
            #       # Games.qcow2
            #       {
            #         type = "volume";
            #         device = "disk";
            #         driver = {
            #           name = "qemu";
            #           type = "qcow2";
            #           cache = "none";
            #           discard = "unmap";
            #         };
            #         source = {
            #           pool = "DiskPool";
            #           volume = "Games.qcow2";
            #         };
            #         target = {
            #           dev = "vdd";
            #           bus = "virtio";
            #         };
            #       }

            #       # Data.qcow2
            #       {
            #         type = "volume";
            #         device = "disk";
            #         driver = {
            #           name = "qemu";
            #           type = "qcow2";
            #           cache = "none";
            #           discard = "unmap";
            #         };
            #         source = {
            #           pool = "DiskPool";
            #           volume = "Data.qcow2";
            #         };
            #         target = {
            #           dev = "vde";
            #           bus = "virtio";
            #         };
            #       }
            #     ];
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
                source = {address = pci_address 6 0 3;};
                # Backend USB Controller 06:00.3
                address = pci_address 9 0 0;
              }
            ];
            interface = [
              {
                type = "bridge";
                model = {type = "virtio";};
                source = {bridge = "br0";};
              }
              {
                type = "hostdev";
                managed = true;
                source = {address = pci_address 3 0 1;};
                # MLX 5 03:00.1
                mac = {address = "56:58:18:5c:22:b0";};
              }
            ];
          };
        qemu-commandline = {
          arg = [
            {value = "-overcommit";}
            {value = "cpu-pm=off";}
            {value = "-fw_cfg";}
            {value = "opt/ovmf/X-PciMmio64Mb,string=65536";}
            {value = "-device";}
            {value = "{\"driver\":\"ivshmem-plain\",\"id\":\"shmem0\",\"memdev\":\"looking-glass\"}";}
            {value = "-object";}
            {value = "{\"qom-type\":\"memory-backend-file\",\"id\":\"looking-glass\",\"mem-path\":\"/dev/kvmfr0\",\"size\":268435456,\"share\":true}";}
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
  active = false;
}
