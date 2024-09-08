{
  lib,
  pkgs,
  config,
  NixVirt,
  ...
}: {
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
    install_virtio ? false,
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
          bootmenu = {enable = false;};
        };
      devices = base.devices // devices_override;
    };
}
