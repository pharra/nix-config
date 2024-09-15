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
    Microsoft = windows_template {
      name = "Microsoft";
      uuid = "ee43005c-2e7b-4af2-bfae-8c52eeb22679";
      memory = {
        count = 32;
        unit = "GiB";
      };
      storage_vol = {
        pool = "VMPool";
        volume = "Microsoft.qcow2";
      };
      nvram_path = /home/wf/Data/RAMPool/Microsoft.fd;
      no_graphics = true;
      virtio_net = true;
    };
  in
    NixVirt.lib.domain.writeXML (
      Microsoft
      // {
        vcpu = {
          placement = "static";
          count = 12;
        };
        cpu = {
          mode = "host-passthrough";
          check = "full";
          migratable = true;
          topology = {
            sockets = 1;
            dies = 1;
            cores = 6;
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
              cpuset = "0";
            }
            {
              vcpu = 1;
              cpuset = "1";
            }
            {
              vcpu = 2;
              cpuset = "2";
            }
            {
              vcpu = 3;
              cpuset = "3";
            }
            {
              vcpu = 4;
              cpuset = "4";
            }
            {
              vcpu = 5;
              cpuset = "5";
            }
            {
              vcpu = 6;
              cpuset = "6";
            }
            {
              vcpu = 7;
              cpuset = "7";
            }

            # core 1
            {
              vcpu = 8;
              cpuset = "16";
            }
            {
              vcpu = 9;
              cpuset = "17";
            }
            {
              vcpu = 10;
              cpuset = "18";
            }
            {
              vcpu = 11;
              cpuset = "19";
            }
            {
              vcpu = 12;
              cpuset = "20";
            }
            {
              vcpu = 13;
              cpuset = "21";
            }
            {
              vcpu = 14;
              cpuset = "22";
            }
            {
              vcpu = 15;
              cpuset = "23";
            }
          ];
          emulatorpin = {
            cpuset = "0,12";
          };
          iothreadpin = {
            iothread = 1;
            cpuset = "0,12";
          };
        };
        memoryBacking = {
          hugepages = {};
        };
        devices =
          Microsoft.devices
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
            ];
            interface = [
              {
                type = "bridge";
                model = {type = "virtio";};
                source = {bridge = "br0";};
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
      }
    );
}
