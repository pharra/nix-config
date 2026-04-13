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

  Pat = windows_template {
    name = "Pat";
    uuid = "ee43005c-2e7b-4af2-bfae-8c52eeb22679";
    memory = {
      count = 32;
      unit = "GiB";
    };
    nvram_path = /fluent/RAMPool/Pat.fd;
    no_graphics = true;
    virtio_net = true;
    storage_vol = /fluent/DiskPool/Pat.qcow2;
    # install_vol = /fluent/ISOPool/Windows-25H2.iso;
  };
in {
  virtualisation.libvirt.connections."qemu:///system" = {
    domains = [
      {
        definition = NixVirt.lib.domain.writeXML (
          Pat
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
              Pat.clock
              // {
                timer =
                  lib.lists.remove {
                    name = "hpet";
                    present = false;
                  }
                  Pat.clock.timer
                  ++ [
                    {
                      name = "hpet";
                      present = true;
                    }
                  ];
              };
            os =
              Pat.os
              // {
                boot = null;
                bootmenu = {enable = false;};
                smbios = {
                  mode = "host";
                };
              };
            features =
              Pat.features
              // {
                kvm = {
                  hidden.state = true;
                };
                hyperv =
                  Pat.features.hyperv
                  // {
                    vendor_id = {
                      state = true;
                      value = "1234567890ab";
                    };
                  };
              };
            devices =
              Pat.devices
              // {
                # disk =
                #   if builtins.isNull Pat.devices.disk
                #   then []
                #   else
                #     Pat.devices.disk
                #     ++ [
                #       # Games.qcow2
                #       {
                #         type = "volume";
                #         device = "disk";
                #         driver = {
                #           name = "qemu";
                #           type = "qcow2";
                #           cache = "none";
                #           discard = "unmap";
                #         };
                #         source = {
                #           pool = "DiskPool";
                #           volume = "Games.qcow2";
                #         };
                #         target = {
                #           dev = "vdd";
                #           bus = "virtio";
                #         };
                #       }

                #       # Data.qcow2
                #       {
                #         type = "volume";
                #         device = "disk";
                #         driver = {
                #           name = "qemu";
                #           type = "qcow2";
                #           cache = "none";
                #           discard = "unmap";
                #         };
                #         source = {
                #           pool = "DiskPool";
                #           volume = "Data.qcow2";
                #         };
                #         target = {
                #           dev = "vde";
                #           bus = "virtio";
                #         };
                #       }
                #     ];
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

  virtualisation.libvirtd.hooks.qemu."10-Pat" = pkgs.writeShellScript "pat-qemu-hook" ''
    machine=$1
    command=$2
    log_tag="libvirt-hook-Pat"

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

    # === 新增：cgroup v2 isolated partition（特定於 VM "Pat"）===
    setup_isolated_partition() {
      local vcpus="8-15,24-31"   # VM 使用 CCD0
      local hcpus="0-7,16-23"  # 主机剩余 CCD1
      local cgroup_path="/sys/fs/cgroup/pat-isolated"   # 特定於此 VM 的隔离路径

      log "Setting up per-VM cgroup v2 isolated partition: $cgroup_path (VM=$vcpus | Host=$hcpus)"

      # 启用 cpuset controller
      ${pkgs.coreutils-full}/bin/echo "+cpuset" | ${pkgs.coreutils-full}/bin/tee /sys/fs/cgroup/cgroup.subtree_control >/dev/null 2>&1 || true

      # 创建 cgroup
      mkdir -p "$cgroup_path"
      ${pkgs.coreutils-full}/bin/echo "+cpuset" | ${pkgs.coreutils-full}/bin/tee "$cgroup_path/cgroup.subtree_control" >/dev/null 2>&1 || true

      # 设置 CPU 和内存节点
      ${pkgs.coreutils-full}/bin/echo "$vcpus" | ${pkgs.coreutils-full}/bin/tee "$cgroup_path/cpuset.cpus" >/dev/null
      ${pkgs.coreutils-full}/bin/echo "0" | ${pkgs.coreutils-full}/bin/tee "$cgroup_path/cpuset.mems" >/dev/null

      # 关键：设置为 isolated（关闭 load balancing，最大化减少主机干扰）
      ${pkgs.coreutils-full}/bin/echo "isolated" | ${pkgs.coreutils-full}/bin/tee "$cgroup_path/cpuset.cpus.partition" >/dev/null

      # 限制主机所有 slice（包括 init/systemd）
      ${pkgs.systemd}/bin/systemctl set-property --runtime system.slice AllowedCPUs="$hcpus"
      ${pkgs.systemd}/bin/systemctl set-property --runtime user.slice AllowedCPUs="$hcpus"
      ${pkgs.systemd}/bin/systemctl set-property --runtime init.scope AllowedCPUs="$hcpus"

      log "Per-VM isolated partition setup completed: $cgroup_path"
    }

    restore_isolated_partition() {
      local cgroup_path="/sys/fs/cgroup/pat-isolated"

      log "Restoring full CPU access and removing per-VM isolated partition $cgroup_path"

      ${pkgs.systemd}/bin/systemctl set-property --runtime system.slice AllowedCPUs=0-31
      ${pkgs.systemd}/bin/systemctl set-property --runtime user.slice AllowedCPUs=0-31
      ${pkgs.systemd}/bin/systemctl set-property --runtime init.scope AllowedCPUs=0-31

      rmdir "$cgroup_path" 2>/dev/null || true
      log "Per-VM isolated partition restored"
    }

    log "qemu hook invoked: machine=$machine command=$command"

    if [ "$machine" == "Pat" ]; then

      if [ "$command" == "prepare" ]; then
        log "Pat: preparing - GPU detach + conditional hugepages + CPU mask + EPP tuning"

        # 1. GPU detach
        log "Pat: detaching PCI device pci_0000_03_00_1"
        ${pkgs.libvirt}/bin/virsh nodedev-detach --device pci_0000_03_00_1

        ${pkgs.systemd}/bin/systemctl stop display-manager.service
        sleep 3 # 確保 display manager 已完全停止，避免與 GPU 佔用衝突

        # Unbind VTconsoles
        ${pkgs.coreutils-full}/bin/echo 0 > /sys/class/vtconsole/vtcon0/bind
        ${pkgs.coreutils-full}/bin/echo 0 > /sys/class/vtconsole/vtcon1/bind

        # Unbind EFI-Framebuffer
        ${pkgs.coreutils-full}/bin/echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

        sleep 2

        ${pkgs.libvirt}/bin/virsh nodedev-detach --device pci_0000_01_00_0
        ${pkgs.libvirt}/bin/virsh nodedev-detach --device pci_0000_01_00_1

        sleep 2 # 確保 GPU 已完全釋放
        ${pkgs.systemd}/bin/systemctl start display-manager.service

        log "Pat: GPU detached successfully"

        # 2. 讀取 XML 並嘗試動態申請 hugepages
        XML=$( ${pkgs.coreutils-full}/bin/cat )
        if ! allocate_dynamic_hugepages "$XML"; then
          log "Hugepages allocation failed or skipped → continuing anyway"
        fi

        # 3. 新增：建立 per-VM cgroup v2 isolated partition
        setup_isolated_partition

        # 4. EPP 調整
        VM_CPUS="8-15,24-31"
        log "Pat: setting EPP=performance on pinned CPUs ($VM_CPUS)"
        set_epp "$VM_CPUS" "performance"

        # 驗證
        if [ -f "/sys/devices/system/cpu/cpu8/cpufreq/energy_performance_preference" ]; then
          local sample=$( ${pkgs.coreutils-full}/bin/cat /sys/devices/system/cpu/cpu8/cpufreq/energy_performance_preference 2>/dev/null || echo "read-failed" )
          log "Pat: verification - cpu8 EPP now: $sample"
        fi

      elif [ "$command" == "started" ]; then
        log "Pat: started - moving QEMU PID to per-VM isolated cgroup"

        local cgroup_path="/sys/fs/cgroup/pat-isolated"
        if [ -d "$cgroup_path" ]; then
          QEMU_PID=$(pgrep -f "qemu-system.*$machine" | head -n1)
          if [ -n "$QEMU_PID" ]; then
            ${pkgs.coreutils-full}/bin/echo "$QEMU_PID" | ${pkgs.coreutils-full}/bin/tee "$cgroup_path/cgroup.procs" >/dev/null 2>&1 || true
            log "Successfully moved QEMU PID $QEMU_PID into $cgroup_path"
          else
            log "WARNING: QEMU PID not found"
          fi
        fi

      elif [ "$command" == "release" ]; then
        log "Pat: release - restoring environment"

        # 恢復 per-VM isolated partition
        restore_isolated_partition

        VM_CPUS="8-15,24-31"
        log "Pat: restoring EPP=balance_performance on former pinned CPUs ($VM_CPUS)"
        set_epp "$VM_CPUS" "balance_performance"

        log "Pat: reattaching PCI device + hugepages cleanup"
        ${pkgs.libvirt}/bin/virsh nodedev-reattach --device pci_0000_03_00_1
        ${pkgs.coreutils-full}/bin/echo 0 > /proc/sys/vm/nr_hugepages

        ${pkgs.libvirt}/bin/virsh nodedev-reattach --device pci_0000_01_00_0
        ${pkgs.libvirt}/bin/virsh nodedev-reattach --device pci_0000_01_00_1
        sleep 2

        # Rebind VT consoles
        ${pkgs.coreutils-full}/bin/echo 1 > /sys/class/vtconsole/vtcon0/bind
        ${pkgs.coreutils-full}/bin/echo 1 > /sys/class/vtconsole/vtcon1/bind
        ${pkgs.coreutils-full}/bin/echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind
        sleep 2

        # fix the issue that can't run some games (failed to initialize vulkan driver) after attach, maybe related to udev rules or something, not sure
        ${pkgs.systemd}/bin/systemctl restart systemd-udevd.service && ${pkgs.systemd}/bin/systemctl restart systemd-modules-load.service && ${pkgs.systemd}/bin/systemctl restart display-manager.service

        log "Pat: GPU reattached and hugepages cleaned up"

        log "Pat: cleanup completed"

      else
        log "Pat: unhandled command=$command"
      fi

    else
      log "ignoring machine=$machine command=$command"
    fi
  '';
}
