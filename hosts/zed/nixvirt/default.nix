{
  lib,
  pkgs,
  config,
  NixVirt,
  ...
} @ args: let
  Windows = import ./Windows.nix args;
  Microsoft = import ./Microsoft.nix args;
  attach_gpu = pkgs.writeShellScriptBin "attach_gpu" ''
    nvidia_vendor="10de:2684"
    sound_vendor="10de:22ba"
    nvidia_bus_path=`${pkgs.pciutils}/bin/lspci -mm -d $nvidia_vendor | ${pkgs.gawk}/bin/awk '{ print $1 }'`
    sound_bus_path=`${pkgs.pciutils}/bin/lspci -mm -d $sound_vendor | ${pkgs.gawk}/bin/awk '{ print $1 }'`
    ${pkgs.coreutils-full}/bin/echo -n "0000:$nvidia_bus_path" | ${pkgs.coreutils-full}/bin/tee /sys/bus/pci/drivers/vfio-pci/unbind
    ${pkgs.coreutils-full}/bin/echo -n "0000:$sound_bus_path" | ${pkgs.coreutils-full}/bin/tee /sys/bus/pci/drivers/vfio-pci/unbind
    ${pkgs.coreutils-full}/bin/echo -n "0000:$sound_bus_path" | ${pkgs.coreutils-full}/bin/tee /sys/bus/pci/drivers/snd_hda_intel/bind
    ${pkgs.kmod}/bin/modprobe nvidia_drm modeset=1
    ${pkgs.kmod}/bin/modprobe nvidia nvidia_modeset nvidia_uvm
  '';

  detach_gpu = pkgs.writeShellScriptBin "detach_gpu" ''
    ${pkgs.coreutils-full}/bin/echo -n "remove" | ${pkgs.coreutils-full}/bin/tee /sys/class/drm/card0/uevent
    ${pkgs.lsof}/bin/lsof -e /run/user/1000/doc /dev/nvidia0 | ${pkgs.gawk}/bin/awk '{print $2}' | ${pkgs.findutils}/bin/xargs -I {} kill {}
    ${pkgs.lsof}/bin/lsof -e /run/user/1000/doc /dev/dri/card0 | ${pkgs.gawk}/bin/awk '{print $2}' | ${pkgs.findutils}/bin/xargs -I {} kill {}
    ${pkgs.lsof}/bin/lsof -e /run/user/1000/doc /dev/dri/renderD129 | ${pkgs.gawk}/bin/awk '{print $2}' | ${pkgs.findutils}/bin/xargs -I {} kill {}
    ${pkgs.coreutils-full}/bin/sleep 5s #allow graceful shutdown
    #if still alive
    ${pkgs.lsof}/bin/lsof -e /run/user/1000/doc /dev/nvidia0 | ${pkgs.gawk}/bin/awk '{print $2}' | ${pkgs.findutils}/bin/xargs -I {} kill -9{}
    ${pkgs.lsof}/bin/lsof -e /run/user/1000/doc /dev/dri/card0 | ${pkgs.gawk}/bin/awk '{print $2}' | ${pkgs.findutils}/bin/xargs -I {} kill -9{}
    ${pkgs.lsof}/bin/lsof -e /run/user/1000/doc /dev/dri/renderD129 | ${pkgs.gawk}/bin/awk '{print $2}' | ${pkgs.findutils}/bin/xargs -I {} kill -9 {}
    ${pkgs.coreutils-full}/bin/sleep 2s #prevent unloading breaking
    ${pkgs.kmod}/bin/rmmod nvidia_drm
    ${pkgs.kmod}/bin/rmmod nvidia_modeset
    ${pkgs.kmod}/bin/rmmod nvidia_uvm
    ${pkgs.kmod}/bin/rmmod nvidia

    nvidia_vendor="10de:2684"
    sound_vendor="10de:22ba"
    nvidia_bus_path=`${pkgs.pciutils}/bin/lspci -mm -d $nvidia_vendor | ${pkgs.gawk}/bin/awk '{ print $1 }'`
    sound_bus_path=`${pkgs.pciutils}/bin/lspci -mm -d $sound_vendor | ${pkgs.gawk}/bin/awk '{ print $1 }'`

    ${pkgs.coreutils-full}/bin/echo -n "0000:$sound_bus_path" | ${pkgs.coreutils-full}/bin/tee /sys/bus/pci/drivers/snd_hda_intel/unbind
    ${pkgs.coreutils-full}/bin/echo -n "0000:$nvidia_bus_path" | ${pkgs.coreutils-full}/bin/tee /sys/bus/pci/drivers/vfio-pci/bind
    ${pkgs.coreutils-full}/bin/echo -n "0000:$sound_bus_path" | ${pkgs.coreutils-full}/bin/tee /sys/bus/pci/drivers/vfio-pci/bind
  '';
in {
  environment = {
    systemPackages = with pkgs; [
      NixVirt.packages.x86_64-linux.default
      attach_gpu
      detach_gpu
    ];
  };

  virtualisation.libvirt.enable = true;
  virtualisation.libvirt.forceRedefine = false;
  virtualisation.libvirt.verbose = true;
  virtualisation.libvirt.connections."qemu:///system" = {
    domains = [
      Windows
      Microsoft
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

  systemd.services.attach_gpu = {
    enable = false;
    script = ''
      ${attach_gpu}/bin/attach_gpu
    '';
    requiredBy = ["libvirtd.service"];
    before = ["libvirtd.service"];
    serviceConfig = {
      Type = "oneshot";
    };
  };

  virtualisation.libvirtd.hooks.qemu."10-cpu-manager" = pkgs.writeShellScript "cpu-qemu-hook" ''
    machine=$1
    command=$2
    # Dynamically VFIO bind/unbind the USB with the VM starting up/stopping
    if [ "$machine" == "Windows" ]; then
      if [ "$command" == "prepare" ]; then
        ${pkgs.coreutils-full}/bin/echo "preparing"
        # ${detach_gpu}/bin/detach_gpu
      elif [ "$command" == "started" ]; then
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=8-15,24-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=8-15,24-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.scope AllowedCPUs=8-15,24-31
      elif [ "$command" == "stopped" ]; then
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=0-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=0-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.scope AllowedCPUs=0-31
        # ${attach_gpu}/bin/attach_gpu
      fi
    fi
  '';
}
