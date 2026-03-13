{
  lib,
  pkgs,
  config,
  NixVirt,
  ...
} @ args: let
  Windows = import ./Oct.nix args;
  Pat = import ./Pat.nix args;
  Linux = import ./Linux.nix args;
in {
  environment = {
    systemPackages = with pkgs; [
      NixVirt.packages.x86_64-linux.default
    ];
  };

  virtualisation.libvirt.enable = true;
  virtualisation.libvirt.verbose = true;
  virtualisation.libvirt.connections."qemu:///system" = {
    domains = [
      Windows
      Pat
      Linux
    ];
  };

  virtualisation.libvirtd.hooks.qemu."10-cpu-manager" = pkgs.writeShellScript "cpu-qemu-hook" ''
    machine=$1
    command=$2
    log_tag="libvirt-hook"

    log() {
      ${pkgs.util-linux}/bin/logger -t "$log_tag" "$1"
    }

    # 輔助函數：設定單顆 CPU 的 EPP
    _set_epp_single() {
      local file="$1"
      local value="$2"
      local cpu="$3"

      if [ ! -f "$file" ]; then
        log "WARNING: EPP file not found for cpu$cpu"
        return 1
      fi

      if ! ${pkgs.coreutils-full}/bin/echo "$value" > "$file" 2>/dev/null; then
        local err=$?
        log "ERROR: Failed to set cpu$cpu EPP to '$value' (errno=$err)"
        return $err
      fi

      log "cpu$cpu EPP → $value"
      return 0
    }

    # 輔助函數：設定多顆 CPU 的 EPP（支援範圍格式）
    set_epp() {
      local cpus_str="$1"
      local value="$2"
      local part start end cpu file

      [ -z "$cpus_str" ] && { log "ERROR: set_epp called with empty cpus_str"; return 1; }
      [ -z "$value" ] && { log "ERROR: set_epp called with empty value"; return 1; }

      local cpu_list
      cpu_list=$( ${pkgs.coreutils-full}/bin/echo "$cpus_str" | ${pkgs.coreutils-full}/bin/tr ',' ' ' | ${pkgs.coreutils-full}/bin/tr -s ' ' | ${pkgs.gnused}/bin/sed 's/^ *//; s/ *$//' )

      [ -z "$cpu_list" ] && { log "ERROR: No valid CPUs parsed from '$cpus_str'"; return 1; }

      for part in $cpu_list; do
        if [[ $part =~ ^([0-9]+)-([0-9]+)$ ]]; then
          start=''${BASH_REMATCH[1]}
          end=''${BASH_REMATCH[2]}

          if (( start > end )); then
            log "WARNING: Invalid range (start > end): $part"
            continue
          fi

          for ((cpu = start; cpu <= end; cpu++)); do
            file="/sys/devices/system/cpu/cpu$cpu/cpufreq/energy_performance_preference"
            _set_epp_single "$file" "$value" "$cpu"
          done

        elif [[ $part =~ ^[0-9]+$ ]]; then
          file="/sys/devices/system/cpu/cpu$part/cpufreq/energy_performance_preference"
          _set_epp_single "$file" "$value" "$part"

        else
          log "WARNING: Invalid CPU specifier '$part' (skipped)"
        fi
      done
    }

    # 動態申請 hugepages 的函數（只在 VM 配置了 <memoryBacking><hugepages> 時執行）
    allocate_dynamic_hugepages() {
      local xml="$1"

      # 精確檢查 /domain/memoryBacking/hugepages 是否存在
      local has_hugepages
      has_hugepages=$( ${pkgs.libxml2}/bin/xmllint --xpath 'count(/domain/memoryBacking/hugepages) > 0' - 2>/dev/null <<< "$xml" && echo 1 || echo 0 )

      if [ "$has_hugepages" -eq 0 ]; then
        log "No <memoryBacking><hugepages> found in VM XML → skipping dynamic hugepages allocation"
        return 0
      fi

      log "Detected <memoryBacking><hugepages> in VM config → proceeding with dynamic allocation"

      # 提取 VM 總記憶體大小（單位 KiB）
      local vm_memory_kib
      vm_memory_kib=$( ${pkgs.libxml2}/bin/xmllint --xpath 'string(/domain/memory[1])' - 2>/dev/null <<< "$xml" )

      if [ -z "$vm_memory_kib" ] || ! [[ "$vm_memory_kib" =~ ^[0-9]+$ ]]; then
        log "ERROR: Failed to parse VM memory size from XML"
        return 1
      fi

      local vm_memory_mib=$(( vm_memory_kib / 1024 ))
      local hugepages=$(( (vm_memory_mib / 2) + 64 ))

      log "VM memory ≈ $vm_memory_mib MiB → requesting $hugepages hugepages (2MB pages + buffer)"

      ${pkgs.coreutils-full}/bin/echo "$hugepages" > /proc/sys/vm/nr_hugepages
      local alloc_pages
      alloc_pages=$( ${pkgs.coreutils-full}/bin/cat /proc/sys/vm/nr_hugepages )
      local tries=0

      while [ "$alloc_pages" -ne "$hugepages" ] && [ "$tries" -lt 1000 ]; do
        ${pkgs.coreutils-full}/bin/echo 1 > /proc/sys/vm/compact_memory
        ${pkgs.coreutils-full}/bin/echo "$hugepages" > /proc/sys/vm/nr_hugepages
        alloc_pages=$( ${pkgs.coreutils-full}/bin/cat /proc/sys/vm/nr_hugepages )
        log "Allocated $alloc_pages / $hugepages hugepages (try $tries)"
        tries=$((tries + 1))
        ${pkgs.coreutils-full}/bin/sleep 0.05
      done

      if [ "$alloc_pages" -ne "$hugepages" ]; then
        log "FAILED to allocate requested hugepages! Reverting to 0..."
        ${pkgs.coreutils-full}/bin/echo 0 > /proc/sys/vm/nr_hugepages
        return 1
      fi

      log "Hugepages successfully allocated ($alloc_pages / $hugepages)"
      return 0
    }

    log "qemu hook invoked: machine=$machine command=$command"

    if [ "$machine" == "Pat" ]; then

      if [ "$command" == "prepare" ]; then
        log "Pat: preparing - GPU detach + conditional hugepages + CPU mask + EPP tuning"

        # 1. GPU detach
        log "Pat: detaching PCI device pci_0000_03_00_1"
        ${pkgs.libvirt}/bin/virsh nodedev-detach --device pci_0000_03_00_1

        # 2. 讀取 XML 並嘗試動態申請 hugepages
        XML=$( ${pkgs.coreutils-full}/bin/cat )
        if ! allocate_dynamic_hugepages "$XML"; then
          log "Hugepages allocation failed or skipped → continuing anyway"
        fi

        # 3. EPP 調整
        VM_CPUS="4-11,20-27"
        log "Pat: setting EPP=performance on pinned CPUs ($VM_CPUS)"
        set_epp "$VM_CPUS" "performance"

        # 驗證
        if [ -f "/sys/devices/system/cpu/cpu8/cpufreq/energy_performance_preference" ]; then
          local sample=$( ${pkgs.coreutils-full}/bin/cat /sys/devices/system/cpu/cpu8/cpufreq/energy_performance_preference 2>/dev/null || echo "read-failed" )
          log "Pat: verification - cpu8 EPP now: $sample"
        fi

        # 4. CPU mask
        log "Pat: applying dedicated CPU mask"
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=0-3,12-19,28-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=0-3,12-19,28-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.scope AllowedCPUs=0-3,12-19,28-31
        log "Pat: dedicated CPU mask applied"

      elif [ "$command" == "started" ]; then
        log "Pat: started, no additional action"

      elif [ "$command" == "stopped" ]; then
        log "Pat: stopped - restoring environment"

        log "Pat: restoring full CPU mask (0-31)"
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=0-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=0-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.scope AllowedCPUs=0-31
        log "Pat: full CPU mask restored"Mar 13 23:41:06 zed libvirt-hook[37297]: ERROR: set_epp called with empty cpus_str

        VM_CPUS="4-11,20-27"
        log "Pat: restoring EPP=balance_performance on former pinned CPUs ($VM_CPUS)"
        set_epp "$VM_CPUS" "balance_performance"

        log "Pat: reattaching PCI device + hugepages cleanup"
        ${pkgs.libvirt}/bin/virsh nodedev-reattach --device pci_0000_03_00_1
        ${pkgs.coreutils-full}/bin/echo 0 > /proc/sys/vm/nr_hugepages
        log "Pat: cleanup completed"

      else
        log "Pat: unhandled command=$command"
      fi

    else
      log "ignoring machine=$machine command=$command"
    fi
  '';
}
