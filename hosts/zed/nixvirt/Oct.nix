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

  Oct = windows_template {
    name = "Oct";
    uuid = "ee43005c-2e7b-4af2-bfae-8c52eeb22678";
    memory = {
      count = 32;
      unit = "GiB";
    };
    nvram_path = /fluent/RAMPool/Oct.fd;
    no_graphics = true;
    virtio_net = true;
    # install_vol = "/home/wf/Data/ISOPool/Win11_24H2_Chinese_Simplified_x64.iso";
  };
in {
  virtualisation.libvirt.connections."qemu:///system" = {
    domains = [
      {
        definition = NixVirt.lib.domain.writeXML (
          Oct
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
              Oct.clock;
            os =
              Oct.os
              // {
                boot = null;
                bootmenu = {enable = false;};
                smbios = {
                  mode = "host";
                };
              };
            features =
              Oct.features
              // {
                kvm = {
                  hidden.state = true;
                };
                hyperv =
                  Oct.features.hyperv
                  // {
                    vendor_id = {
                      state = true;
                      value = "1234567890ab";
                    };
                  };
              };
            devices =
              Oct.devices
              // {
                tpm = {
                  model = "tpm-tis";
                  backend = {
                    type = "passthrough";
                    device = {
                      path = "/dev/tpm0";
                    };
                  };
                };
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
                    source = {address = pci_address 4 0 0;};
                    # Intel SSD 760p 03:00.0
                    address = pci_address 8 0 0;
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
    ];
  };

  virtualisation.libvirtd.hooks.qemu."10-Oct" = pkgs.writeShellScript "oct-qemu-hook" ''
    LOG_TAG="libvirt-hook-Oct"
    source /etc/libvirt/hooks/common-functions.sh

    # VM 专属配置
    VM_NAME="Oct"
    PCI_DEV1="pci_0000_03_00_1"
    PCI_DEV2="pci_0000_01_00_0"
    PCI_DEV3="pci_0000_01_00_1"
    VM_CPUS="8-15,24-31"

    machine=$1 command=$2
    log "hook: machine=$machine command=$command"
    [ "$machine" != "$VM_NAME" ] && { log "ignoring"; exit 0; }

    case $command in
      prepare)
        gpu_prepare "$PCI_DEV1" "$PCI_DEV2" "$PCI_DEV3"
        XML=$($CAT)
        alloc_hugepages "$XML" || log "Hugepages allocation failed (continuing)"
        set_epp "$VM_CPUS" performance
        ;;
      started)
        # 无需操作
        ;;
      release)
        set_epp "$VM_CPUS" balance_performance
        $ECHO 0 > /proc/sys/vm/nr_hugepages
        gpu_release "$PCI_DEV1" "$PCI_DEV2" "$PCI_DEV3"
        log "cleanup done"
        ;;
    esac
  '';
}
