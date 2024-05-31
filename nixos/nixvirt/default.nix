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

  windows_template = {
    name,
    uuid,
    memory,
    storage_vol ? null,
    install_vol ? null,
    virtio_drive ? true,
    virtio_net ? true,
    no_graphics ? false,
    nvram_path,
    install_virtio ? true,
    ...
  }: let
    base =
      NixVirt.lib.domain.templates.windows
      {
        inherit name uuid memory storage_vol install_vol nvram_path virtio_net virtio_drive install_virtio;
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
      os =
        base.os
        // {
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
                    {
                      type = "pci";
                      mode = "subsystem";
                      managed = true;
                      source = {address = pci_address 66 0 1;};
                      # c1 0 1
                      address = pci_address 8 0 0;
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
      {
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
                check = "none";
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
                      source = {address = pci_address 4 0 3;};
                      # USB Controller 04:00.3
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
                      source = {address = pci_address 2 0 0;};
                      # Intel SSD 760p 2:00.0
                      address = pci_address 8 0 0;
                    }
                  ];
                  interface = [
                    {
                      type = "bridge";
                      model = {type = "virtio";};
                      source = {bridge = "br0";};
                    }
                    {
                      type = "bridge";
                      model = {type = "virtio";};
                      source = {bridge = "ib";};
                    }
                    {
                      type = "bridge";
                      model = {type = "virtio";};
                      source = {bridge = "eth";};
                    }
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

  virtualisation.libvirtd.hooks.qemu."10-cpu-manager" = pkgs.writeShellScript "cpu-qemu-hook" ''
    #!/bin/sh
    machine=$1
    command=$2
    # Dynamically VFIO bind/unbind the USB with the VM starting up/stopping
    if [[ "$machine" = "Windows" ]]; then
      if [ "$command" = "started" ]; then
        systemctl set-property --runtime -- system.slice AllowedCPUs=0-2,11-18,27-31
        systemctl set-property --runtime -- user.slice AllowedCPUs=0-2,11-18,27-31
        systemctl set-property --runtime -- init.scope AllowedCPUs=0-2,11-18,27-31
      elif [ "$command" = "release" ]; then
        systemctl set-property --runtime -- system.slice AllowedCPUs=0-31
        systemctl set-property --runtime -- user.slice AllowedCPUs=0-31
        systemctl set-property --runtime -- init.scope AllowedCPUs=0-31
      fi
    fi
  '';
}
