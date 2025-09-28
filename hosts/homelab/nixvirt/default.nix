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
  Kwrt = import ./Kwrt.nix args;
  FnOS = import ./FnOS.nix args;

  attach_gpu = pkgs.writeShellScriptBin "attach_gpu" ''
    nvidia_vendor="$1"
    sound_vendor="$2"

    if [ -z "$nvidia_vendor" ] || [ -z "$sound_vendor" ]; then
      echo "Usage: attach_gpu <nvidia_vendor> <sound_vendor>"
      exit 1
    fi

    nvidia_bus_path=`${pkgs.pciutils}/bin/lspci -mm -d $nvidia_vendor | ${pkgs.gawk}/bin/awk '{ print $1 }'`
    sound_bus_path=`${pkgs.pciutils}/bin/lspci -mm -d $sound_vendor | ${pkgs.gawk}/bin/awk '{ print $1 }'`
    ${pkgs.coreutils-full}/bin/echo -n "0000:$nvidia_bus_path" | ${pkgs.coreutils-full}/bin/tee /sys/bus/pci/drivers/vfio-pci/unbind
    ${pkgs.coreutils-full}/bin/echo -n "0000:$sound_bus_path" | ${pkgs.coreutils-full}/bin/tee /sys/bus/pci/drivers/vfio-pci/unbind
    ${pkgs.coreutils-full}/bin/echo -n "0000:$sound_bus_path" | ${pkgs.coreutils-full}/bin/tee /sys/bus/pci/drivers/snd_hda_intel/bind
    ${pkgs.kmod}/bin/modprobe nvidia_drm modeset=1 fbdev=1
    ${pkgs.kmod}/bin/modprobe nvidia nvidia_modeset nvidia_uvm
  '';

  detach_gpu = pkgs.writeShellScriptBin "detach_gpu" ''
    nvidia_vendor="$1"
    sound_vendor="$2"

    if [ -z "$nvidia_vendor" ] || [ -z "$sound_vendor" ]; then
      echo "Usage: detach_gpu <nvidia_vendor> <sound_vendor>"
      exit 1
    fi

    echo "[$(date)] Looking for devices with vendor IDs: NVIDIA=$nvidia_vendor, Sound=$sound_vendor"

    nvidia_bus_path=`${pkgs.pciutils}/bin/lspci -mm -d $nvidia_vendor | ${pkgs.gawk}/bin/awk '{ print $1 }'`
    sound_bus_path=`${pkgs.pciutils}/bin/lspci -mm -d $sound_vendor | ${pkgs.gawk}/bin/awk '{ print $1 }'`

    if [ -z "$nvidia_bus_path" ]; then
      echo "[$(date)] ERROR: NVIDIA device not found"
      exit 1
    fi
    if [ -z "$sound_bus_path" ]; then
      echo "[$(date)] ERROR: Sound device not found"
      exit 1
    fi

    echo "[$(date)] Found devices at: NVIDIA=$nvidia_bus_path, Sound=$sound_bus_path"

    # Function to check if any process is using NVIDIA devices
    check_nvidia_processes() {
      echo "[$(date)] Checking for processes using NVIDIA devices..."
      local total_count=0
      local devices=(
        "/dev/nvidia0"
        "/dev/dri/by-path/pci-0000:$nvidia_bus_path-card"
        "/dev/dri/by-path/pci-0000:$nvidia_bus_path-render"
      )

      for device in "''${devices[@]}"; do
        if [ -e "$device" ] || [ -n "$(find $device 2>/dev/null)" ]; then
          echo "[$(date)] Checking device: $device"
          local count=$(${pkgs.lsof}/bin/lsof "$device" 2>/dev/null | wc -l)
          if [ $count -gt 0 ]; then
            echo "[$(date)] Found $count processes using device:"
            ${pkgs.lsof}/bin/lsof "$device" 2>/dev/null | awk '{print $9}' | sort -u
            total_count=$((total_count + count))
          fi
        else
          echo "[$(date)] Device not found: $device"
        fi
      done

      if [ $total_count -eq 0 ]; then
        echo "[$(date)] No processes found using any NVIDIA devices"
      else
        echo "[$(date)] Total processes found: $total_count"
      fi
      return $total_count
    }

    # Function to kill processes
    kill_nvidia_processes() {
      local signal=$1
      echo "[$(date)] Attempting to kill processes with signal: ${signal:-SIGTERM}"
      local devices=(
        "/dev/nvidia0"
        "/dev/dri/by-path/pci-0000:$nvidia_bus_path-card"
        "/dev/dri/by-path/pci-0000:$nvidia_bus_path-render"
      )

      for device in "''${devices[@]}"; do
        if [ -e "$device" ] || [ -n "$(find $device 2>/dev/null)" ]; then
          echo "[$(date)] Killing processes using device: $device"
          ${pkgs.lsof}/bin/lsof $device 2>/dev/null | ${pkgs.gawk}/bin/awk 'NR>1 {print $2}' | sort -u | ${pkgs.findutils}/bin/xargs -r kill $signal
        else
          echo "[$(date)] Device not found: $device"
        fi
      done
    }

    # Check if vfio-pci module is loaded
    if ! ${pkgs.kmod}/bin/lsmod | grep -q "^vfio_pci"; then
      echo "[$(date)] ERROR: vfio-pci module is not loaded"
      exit 1
    fi

    # Notify system about GPU removal
    echo "[$(date)] Notifying system about GPU removal"
    ${pkgs.coreutils-full}/bin/echo -n "remove" | ${pkgs.coreutils-full}/bin/tee /sys/bus/pci/devices/0000:$nvidia_bus_path/drm/card*/uevent

    # First try: graceful shutdown
    echo "[$(date)] Starting graceful process shutdown"
    kill_nvidia_processes ""  # SIGTERM

    # Wait and check, retry with SIGTERM up to 3 times
    for i in {1..3}; do
      echo "[$(date)] Waiting for processes to terminate (attempt $i/3)..."
      ${pkgs.coreutils-full}/bin/sleep 2
      check_nvidia_processes
      if [ $? -eq 0 ]; then
        echo "[$(date)] All processes terminated successfully"
        break
      fi
      echo "[$(date)] Attempt $i: Processes still running, retrying SIGTERM..."
      kill_nvidia_processes ""
    done

    # If processes still exist, use SIGKILL
    check_nvidia_processes
    if [ $? -ne 0 ]; then
      echo "[$(date)] Some processes still running, using SIGKILL..."
      kill_nvidia_processes "-9"
      ${pkgs.coreutils-full}/bin/sleep 2
    fi

    # Final check
    check_nvidia_processes
    if [ $? -ne 0 ]; then
      echo "[$(date)] ERROR: Failed to kill all NVIDIA processes"
      exit 1
    fi

    # Check and unload NVIDIA modules if they exist
    modules=("nvidia_drm" "nvidia_modeset" "nvidia_uvm" "nvidia")
    for module in "''${modules[@]}"; do
      if ${pkgs.kmod}/bin/lsmod | grep -q "^$module"; then
        echo "[$(date)] Unloading module: $module"
        if ! ${pkgs.kmod}/bin/rmmod $module; then
          echo "[$(date)] Failed to unload module: $module"
          exit 1
        fi
      fi
    done

    # Unbind and rebind devices
    echo "[$(date)] Unbinding sound device from snd_hda_intel"
    if [ -e "/sys/bus/pci/drivers/snd_hda_intel/unbind" ]; then
      ${pkgs.coreutils-full}/bin/echo -n "0000:$sound_bus_path" | ${pkgs.coreutils-full}/bin/tee /sys/bus/pci/drivers/snd_hda_intel/unbind
    else
      echo "[$(date)] WARNING: snd_hda_intel unbind path not found"
    fi

    echo "[$(date)] Binding devices to vfio-pci"
    if [ ! -e "/sys/bus/pci/drivers/vfio-pci/bind" ]; then
      echo "[$(date)] ERROR: vfio-pci bind path not found"
      exit 1
    fi

    ${pkgs.coreutils-full}/bin/echo -n "0000:$nvidia_bus_path" | ${pkgs.coreutils-full}/bin/tee /sys/bus/pci/drivers/vfio-pci/bind
    ${pkgs.coreutils-full}/bin/echo -n "0000:$sound_bus_path" | ${pkgs.coreutils-full}/bin/tee /sys/bus/pci/drivers/vfio-pci/bind

    # Verify bindings
    if ! [ -e "/sys/bus/pci/drivers/vfio-pci/0000:$nvidia_bus_path" ]; then
      echo "[$(date)] ERROR: Failed to bind NVIDIA device to vfio-pci"
      exit 1
    fi
    if ! [ -e "/sys/bus/pci/drivers/vfio-pci/0000:$sound_bus_path" ]; then
      echo "[$(date)] ERROR: Failed to bind sound device to vfio-pci"
      exit 1
    fi

    echo "[$(date)] GPU detachment completed successfully"
  '';
in {
  environment = {
    systemPackages = with pkgs; [
      NixVirt.packages.x86_64-linux.default
      detach_gpu
      attach_gpu
    ];
  };

  virtualisation.libvirt.enable = true;
  virtualisation.libvirt.verbose = true;
  virtualisation.libvirt.connections."qemu:///system" = {
    domains = [
      ArchLinux
      NixOS
      Windows
      Kwrt
      FnOS
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
    #        echo -n "0000:41:00.0" > /sys/bus/pci/drivers/vfio-pci/unbind
    #        echo 15 > /sys/bus/pci/devices/0000\:41\:00.0/resource1_resize
    #        echo -n "0000:41:00.0" > /sys/bus/pci/drivers/vfio-pci/bind
            echo "preparing"
          elif [ "$command" == "started" ]; then
            ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=0-3,12-19,28-31
            ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=0-3,12-19,28-31
            ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.scope AllowedCPUs=0-3,12-19,28-31
          elif [ "$command" == "stopped" ]; then
            ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=0-31
            ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=0-31
            ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.scope AllowedCPUs=0-31
     #       echo -n "0000:41:00.0" > /sys/bus/pci/drivers/vfio-pci/unbind
     #       echo 8 > /sys/bus/pci/devices/0000\:41\:00.0/resource1_resize
     #       echo -n "0000:41:00.0" > /sys/bus/pci/drivers/vfio-pci/bind
          fi
        fi
  '';

  systemd.services.resize-bar = {
    enable = false;
    script = ''
      set -e
      echo -n "0000:41:00.0" | tee /sys/bus/pci/drivers/vfio-pci/unbind
      echo 15 | tee /sys/bus/pci/devices/0000\:41\:00.0/resource1_resize
      echo -n "0000:41:00.0" | tee /sys/bus/pci/drivers/vfio-pci/bind
    '';
    wantedBy = ["multi-user.target"];
    before = ["libvirtd.service"];
    serviceConfig = {
      Type = "oneshot";
    };
  };

  #services.udev.extraRules = ''
  #  # RTX 4090
  #  ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{device}=="0x2684", ATTR{resource1_resize}="15"
  #'';
}
