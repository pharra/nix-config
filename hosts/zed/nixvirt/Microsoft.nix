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
        count = 16;
        unit = "GiB";
      };
      storage_vol = /fluent/DiskPool/Microsoft.qcow2;
      nvram_path = /home/wf/Data/RAMPool/Microsoft.fd;
      no_graphics = false;
      virtio_net = true;
    };
  in
    NixVirt.lib.domain.writeXML (
      Microsoft
      // {
        vcpu = {
          placement = "static";
          count = 8;
        };
        cpu = {
          mode = "host-passthrough";
          check = "full";
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
        iothreads = {
          count = 1;
        };
        devices =
          Microsoft.devices
          // {
            graphics = {
              type = "spice";
              listen = {type = "none";};
              image = {compression = false;};
              gl = {enable = true;};
            };
            hostdev = [
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
