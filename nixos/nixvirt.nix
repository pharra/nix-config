{
  lib,
  pkgs,
  config,
  NixVirt,
  ...
}: let
  pci_address = bus: slot: function: {
    type = "pci";
    domain = 0;
    bus = bus;
    slot = slot;
    inherit function;
  };
  usb_address = port: {
    type = "usb";
    bus = 0;
    inherit port;
  };
  drive_address = unit: {
    type = "drive";
    controller = 0;
    bus = 0;
    target = 0;
    inherit unit;
  };

  template = {
    type = "kvm";
    name = "ArchLinux";
    uuid = "ee43005c-2e7b-4af2-bfae-8c52eeb22672";
    memory = {
      count = 6;
      unit = "GiB";
    };
    vcpu = {
      placement = "static";
      count = 4;
    };
    os = {
      type = "hvm";
      arch = "x86_64";
      machine = "pc-q35-8.1";
      loader = {
        readonly = true;
        type = "pflash";
        path = "/etc/ovmf/OVMF_CODE.ms.fd";
      };
      nvram = {
        template = "/etc/ovmf/OVMF_VARS.ms.fd";
        path = "/home/wf/Data/RAMPool/ArchLinux.fd";
      };
      #boot = [{dev = "cdrom";} {dev = "hd";}];
      boot = [{dev = "hd";}];
      bootmenu = {enable = true;};
    };
    features = {
      acpi = {};
      apic = {};
    };
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
    clock = {
      offset = "localtime";
      timer = [
        {
          name = "rtc";
          tickpolicy = "catchup";
        }
        {
          name = "pit";
          tickpolicy = "delay";
        }
        {
          name = "hpet";
          present = false;
        }
      ];
    };
    pm = {
      suspend-to-mem = {enabled = false;};
      suspend-to-disk = {enabled = false;};
    };
    devices = {
      emulator = "/run/current-system/sw/bin/qemu-system-x86_64";
      disk = [
        {
          type = "volume";
          device = "disk";
          driver = {
            name = "qemu";
            type = "qcow2";
            cache = "none";
            discard = "unmap";
          };
          source = {
            pool = "VMPool";
            volume = "ArchLinux.qcow2";
          };
          target = {
            bus = "sata";
            dev = "sda";
          };
          address = drive_address 0;
        }
        {
          type = "volume";
          device = "cdrom";
          driver = {
            name = "qemu";
            type = "raw";
          };
          source = {
            pool = "ISOPool";
            volume = "archlinux-2024.04.01-x86_64.iso";
          };
          target = {
            bus = "sata";
            dev = "hdc";
          };
          readonly = true;
          address = drive_address 2;
        }
      ];
      interface = {
        type = "bridge";
        mac = {address = "52:54:00:10:c4:28";};
        source = {bridge = "br0";};
        model = {type = "virtio";};
        address = pci_address 2 1 0;
      };
      input = [
        {
          type = "mouse";
          bus = "usb";
        }
        {
          type = "keyboard";
          bus = "usb";
        }
      ];
      tpm = {
        model = "tpm-crb";
        backend = {
          type = "emulator";
          version = "2.0";
        };
      };
      graphics = {
        type = "spice";
        listen = {type = "none";};
        image = {compression = false;};
        gl = {enable = false;};
      };
      sound = {
        model = "ich9";
        address = pci_address 0 27 0;
      };
      audio = {
        id = 1;
        type = "spice";
      };
      video = {
        model = {
          type = "qxl";
          ram = 65536;
          vram = 65536;
          vgamem = 65536;
          heads = 1;
          primary = true;
          acceleration = {accel3d = true;};
        };
        address = pci_address 0 1 0;
      };
      watchdog = {
        model = "itco";
        action = "reset";
      };
    };
  };
in {
  environment = {
    systemPackages = with pkgs; [
      NixVirt.packages.x86_64-linux.default
    ];
  };

  virtualisation.libvirt.enable = true;
  virtualisation.libvirt.connections."qemu:///system" = {
    domains = [
      {
        definition = let
          ArchLinux = template;
        in
          NixVirt.lib.domain.writeXML (ArchLinux
            // {
              devices =
                ArchLinux.devices
                // {
                  hostdev = [
                    {
                      type = "pci";
                      mode = "subsystem";
                      managed = true;
                      source = {address = pci_address 193 0 0;};
                      # c1 0 0
                      address = pci_address 193 0 0 // {multifunction = true;};
                    }
                    {
                      type = "pci";
                      mode = "subsystem";
                      managed = true;
                      source = {address = pci_address 193 0 1;};
                      # c1 0 1
                      address = pci_address 193 0 1 // {multifunction = true;};
                    }
                    {
                      type = "pci";
                      mode = "subsystem";
                      managed = true;
                      source = {address = pci_address 4 0 3;};
                      # c1 0 1
                      address = pci_address 6 0 0;
                    }
                    {
                      type = "pci";
                      mode = "subsystem";
                      managed = true;
                      source = {address = pci_address 68 0 3;};
                      # c1 0 1
                      address = pci_address 7 0 0;
                    }
                  ];
                  video = {
                    model = {
                      type = "none";
                    };
                  };
                  interface = {
                    type = "bridge";
                    model = {type = "virtio";};
                    source = {bridge = "br0";};
                  };
                  channel = [];
                  graphics = null;
                  audio = null;
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
            });
      }
    ];
    pools = [
      {
        definition = NixVirt.lib.pool.writeXML {
          name = "VMPool";
          uuid = "650c5bbb-eebd-4cea-8a2f-36e1a75a8683";
          type = "dir";
          target = {path = "/home/wf/Data/VMPool";};
        };
      }

      {
        definition = NixVirt.lib.pool.writeXML {
          name = "ISOPool";
          uuid = "650c5bbb-eebd-4cea-8a2f-36e1a75a8684";
          type = "dir";
          target = {path = "/home/wf/Data/ISOPool";};
        };
      }

      {
        definition = NixVirt.lib.pool.writeXML {
          name = "RAMPool";
          uuid = "650c5bbb-eebd-4cea-8a2f-36e1a75a8685";
          type = "dir";
          target = {path = "/home/wf/Data/RAMPool";};
        };
      }
    ];
  };
}
