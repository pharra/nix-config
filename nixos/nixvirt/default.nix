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

  linux_template = {
    name,
    uuid,
    memory,
    storage_vol,
    install_vol ? null,
    virtio_drive ? true,
    virtio_video ? true,
    no_graphics ? false,
    nvram_path,
    ...
  }: let
    base =
      NixVirt.lib.domain.templates.linux
      {
        inherit name uuid memory storage_vol install_vol virtio_drive virtio_video;
      };

    devices_override =
      {
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
      }
      // (
        if no_graphics
        then {
          channel = null;
          graphics = null;
          audio = null;
          video = {
            model = {
              type = "none";
            };
          };
          redirdev = null;
        }
        else {}
      );
  in
    base
    // {
      vcpu = {
        placement = "static";
        count = 4;
      };
      os =
        base.os
        // {
          loader = {
            readonly = true;
            type = "pflash";
            path = "${pkgs.OVMFFull.fd}/FV/OVMF_CODE.ms.fd";
          };
          nvram = {
            template = "${pkgs.OVMFFull.fd}/FV/OVMF_VARS.ms.fd";
            path = nvram_path;
          };
          bootmenu = {enable = true;};
        };
      devices = base.devices // devices_override;
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
          ArchLinux = linux_template {
            name = "ArchLinux";
            uuid = "ee43005c-2e7b-4af2-bfae-8c52eeb22672";
            memory = {
              count = 6;
              unit = "GiB";
            };
            storage_vol = {
              pool = "VMPool";
              volume = "ArchLinux.qcow2";
            };
            install_vol = {
              pool = "ISOPool";
              volume = "archlinux-2024.04.01-x86_64.iso";
            };
            nvram_path = /home/wf/Data/RAMPool/ArchLinux.fd;
            no_graphics = true;
          };
        in
          NixVirt.lib.domain.writeXML (
            ArchLinux
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
                ArchLinux.devices
                // {
                  interface = {
                    type = "bridge";
                    model = {type = "virtio";};
                    source = {bridge = "br0";};
                  };
                };
            }
          );
      }
      {
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
                  hostdev = [
                    {
                      type = "pci";
                      mode = "subsystem";
                      managed = true;
                      source = {address = pci_address 193 0 0;};
                      # c1 0 0
                      address = pci_address 5 0 0 // {multifunction = true;};
                    }
                    {
                      type = "pci";
                      mode = "subsystem";
                      managed = true;
                      source = {address = pci_address 193 0 1;};
                      # c1 0 1
                      address = pci_address 5 0 1 // {multifunction = true;};
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
