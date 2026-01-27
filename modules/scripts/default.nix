{
  config,
  lib,
  pkgs,
  libs,
  ...
}:
with lib; let
  cfg = config.services.pharra.scripts;

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
    ${pkgs.coreutils-full}/bin/echo -n "nvidia" | ${pkgs.coreutils-full}/bin/tee /sys/bus/pci/devices/0000:$nvidia_bus_path/driver_override
    ${pkgs.coreutils-full}/bin/echo -n "snd_hda_intel" | ${pkgs.coreutils-full}/bin/tee /sys/bus/pci/devices/0000:$sound_bus_path/driver_override
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

    if ! ${pkgs.kmod}/bin/lsmod | grep -q "^vfio_pci"; then
      echo "[$(date)] ERROR: vfio-pci module is not loaded"
      exit 1
    fi

    echo "[$(date)] Notifying system about GPU removal"
    ${pkgs.systemd}/bin/udevadm trigger -c remove /dev/dri/by-path/0000:$nvidia_bus_path-render
    ${pkgs.systemd}/bin/udevadm trigger -c remove /dev/dri/by-path/0000:$nvidia_bus_path-card
    ${pkgs.coreutils-full}/bin/echo -n "remove" | ${pkgs.coreutils-full}/bin/tee /sys/bus/pci/devices/0000:$nvidia_bus_path/drm/card*/uevent

    echo "[$(date)] Starting graceful process shutdown"
    kill_nvidia_processes ""

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

    check_nvidia_processes
    if [ $? -ne 0 ]; then
      echo "[$(date)] Some processes still running, using SIGKILL..."
      kill_nvidia_processes "-9"
      ${pkgs.coreutils-full}/bin/sleep 2
    fi

    check_nvidia_processes
    if [ $? -ne 0 ]; then
      echo "[$(date)] ERROR: Failed to kill all NVIDIA processes"
      exit 1
    fi

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

    ${pkgs.coreutils-full}/bin/echo -n "vfio-pci" | ${pkgs.coreutils-full}/bin/tee /sys/bus/pci/devices/0000:$nvidia_bus_path/driver_override
    ${pkgs.coreutils-full}/bin/echo -n "vfio-pci" | ${pkgs.coreutils-full}/bin/tee /sys/bus/pci/devices/0000:$sound_bus_path/driver_override
    ${pkgs.coreutils-full}/bin/echo -n "0000:$nvidia_bus_path" | ${pkgs.coreutils-full}/bin/tee /sys/bus/pci/drivers/vfio-pci/bind
    ${pkgs.coreutils-full}/bin/echo -n "0000:$sound_bus_path" | ${pkgs.coreutils-full}/bin/tee /sys/bus/pci/drivers/vfio-pci/bind

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

  init-fluent-disk = pkgs.writeShellScriptBin "init-fluent-disk" ''
    zpool create -f -o ashift=14 fluent /dev/zvol/data/fluent_system
    mkfs.btrfs -L fluent_nix -f /dev/zvol/data/fluent_nix
    mkfs.vfat -n fluent_boot /dev/zvol/data/fluent_boot-part1

    zfs create fluent/nix
    zfs create fluent/nix/persistent
    zfs create fluent/nix/var
    zfs create fluent/tmp

    zpool export fluent
  '';

  mount-fluent = pkgs.writeShellScriptBin "mount-fluent" ''
    zpool import -f fluent

    mkdir /fluent/boot/efi -p
    mount /dev/disk/by-label/fluent_boot /fluent/boot/efi

    mkdir /fluent/nix/store -p
    mount -t btrfs -o compress-force=zstd:19 /dev/disk/by-label/fluent_nix /fluent/nix/store
  '';

  umount-fluent = pkgs.writeShellScriptBin "umount-fluent" ''
    umount /fluent/nix/store
    umount /fluent/boot/efi

    zpool export -f fluent
  '';

  custom_edid = pkgs.runCommand "edid-custom" {} ''
    mkdir -p "$out/lib/firmware/edid"

    # this edid you can copy from your real monitor, check below

    base64 -d > "$out/lib/firmware/edid/custom1.bin" <<'EOF'
    AP///////wAx2DQSAAAAACIaAQOAYDZ4D+6Ro1RMmSYPUFQvzwAxWUVZgYCBQJBAlQCpQLMACOgAMPJwWoCwWIoAwBwyAAAeAAAA/QAYVRiHPAAKICAgICAgAAAA/AB2aXZpZAogICAgICAgAAAAEAAAAAAAAAAAAAAAAAAAAXsCAz/xUWFgX15dEB8EEyIhIAUUAhEBIwkHB4MBAABtAwwAEAAAPCEAYAECA2fYXcQBeAAA4gDK4wUAAOMGAQBN0ACg8HA+gDAgNQDAHDIAAB4aNoCgcDgfQDAgNQDAHDIAABoaHQCAUdAcIECANQDAHDIAABwAAAAAAAAAAAAAgg==
    EOF
  '';

  add_monitor = pkgs.writeShellScriptBin "add_monitor" ''
    gpu_vendor="1002:164e"
    gpu_bus_path=`${pkgs.pciutils}/bin/lspci -mm -d $gpu_vendor | ${pkgs.gawk}/bin/awk '{ print $1 }'`
    ${pkgs.coreutils-full}/bin/cat ${custom_edid}/lib/firmware/edid/custom1.bin > /sys/kernel/debug/dri/0000:$gpu_bus_path/DP-2/edid_override
    ${pkgs.coreutils-full}/bin/echo -n "on" | ${pkgs.coreutils-full}/bin/tee /sys/kernel/debug/dri/0000:$gpu_bus_path/DP-2/force
    ${pkgs.coreutils-full}/bin/echo -n "1" | ${pkgs.coreutils-full}/bin/tee /sys/kernel/debug/dri/0000:$gpu_bus_path/DP-2/trigger_hotplug
  '';

  remove_monitor = pkgs.writeShellScriptBin "remove_monitor" ''
    gpu_vendor="1002:164e"
    gpu_bus_path=`${pkgs.pciutils}/bin/lspci -mm -d $gpu_vendor | ${pkgs.gawk}/bin/awk '{ print $1 }'`
    ${pkgs.coreutils-full}/bin/echo -n "reset" | ${pkgs.coreutils-full}/bin/tee /sys/kernel/debug/dri/0000:$gpu_bus_path/DP-2/edid_override
    ${pkgs.coreutils-full}/bin/echo -n "off" | ${pkgs.coreutils-full}/bin/tee /sys/kernel/debug/dri/0000:$gpu_bus_path/DP-2/force
    ${pkgs.coreutils-full}/bin/echo -n "1" | ${pkgs.coreutils-full}/bin/tee /sys/kernel/debug/dri/0000:$gpu_bus_path/DP-2/trigger_hotplug
  '';
in {
  options = {
    services.pharra.scripts = {
      enable = mkEnableOption "custom scripts";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      init-fluent-disk
      mount-fluent
      umount-fluent
      add_monitor
      remove_monitor

      attach_gpu
      detach_gpu

      spdk-python
    ];
  };
}
