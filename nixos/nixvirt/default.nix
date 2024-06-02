{
  lib,
  pkgs,
  config,
  NixVirt,
  ...
} @ args: let
  NixOS = import ./NixOS.nix args;
  ArchLinux = import ./ArchLinux.nix args;
  Windows = import ./Windows.nix args;
in {
  environment = {
    systemPackages = with pkgs; [
      NixVirt.packages.x86_64-linux.default
    ];
  };

  virtualisation.libvirt.enable = true;
  virtualisation.libvirt.connections."qemu:///system" = {
    domains = [
      ArchLinux
      NixOS
      Windows
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
    machine=$1
    command=$2
    # Dynamically VFIO bind/unbind the USB with the VM starting up/stopping
    if [ "$machine" == "Windows" ]; then
      if [ "$command" == "prepare" ]; then
        echo -n "0000:41:00.0" > /sys/bus/pci/drivers/vfio-pci/unbind
        echo 15 > /sys/bus/pci/devices/0000\:41\:00.0/resource1_resize
        echo -n "0000:41:00.0" > /sys/bus/pci/drivers/vfio-pci/bind
      elif [ "$command" == "started" ]; then
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=0-2,11-18,27-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=0-2,11-18,27-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.scope AllowedCPUs=0-2,11-18,27-31
      elif [ "$command" == "stopped" ]; then
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=0-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=0-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.scope AllowedCPUs=0-31
        echo -n "0000:41:00.0" > /sys/bus/pci/drivers/vfio-pci/unbind
        echo 8 > /sys/bus/pci/devices/0000\:41\:00.0/resource1_resize
        echo -n "0000:41:00.0" > /sys/bus/pci/drivers/vfio-pci/bind
      fi
    fi
  '';

  services.udev.extraRules = ''
    # RTX 4090
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{device}=="0x2684", ATTR{resource1_resize}="15"
  '';
}
