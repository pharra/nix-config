{
  lib,
  pkgs,
  config,
  NixVirt,
  ...
}: let
  # 公共 Shell 函数（会被 source 到每个 hook 脚本中）
  commonHookFunctions = ''
    : ''${LOGGER:=${pkgs.util-linux}/bin/logger}
    : ''${ECHO:=${pkgs.coreutils-full}/bin/echo}
    : ''${CAT:=${pkgs.coreutils-full}/bin/cat}
    : ''${SLEEP:=${pkgs.coreutils-full}/bin/sleep}
    : ''${SYSTEMCTL:=${pkgs.systemd}/bin/systemctl}
    : ''${VIRSH:=${pkgs.libvirt}/bin/virsh}
    : ''${XMLLINT:=${pkgs.libxml2}/bin/xmllint}
    : ''${SED:=${pkgs.gnused}/bin/sed}
    : ''${FUSER:=${pkgs.busybox}/bin/fuser}

    log() { $LOGGER -t "$LOG_TAG" "$@"; }

    # CPU EPP 设置（支持范围格式）
    set_epp() {
      local cpus="$1" value="$2" part start end
      for part in $($ECHO "$cpus" | $SED 's/,/ /g'); do
        case $part in
          *-*)
            start=''${part%-*}
            end=''${part#*-}
            for ((cpu=start; cpu<=end; cpu++)); do
              $ECHO "$value" > "/sys/devices/system/cpu/cpu$cpu/cpufreq/energy_performance_preference" 2>/dev/null && \
                log "cpu$cpu EPP → $value" || log "FAILED to set cpu$cpu EPP"
            done ;;
          [0-9]*)
            $ECHO "$value" > "/sys/devices/system/cpu/cpu$part/cpufreq/energy_performance_preference" 2>/dev/null && \
              log "cpu$part EPP → $value" || log "FAILED to set cpu$part EPP" ;;
        esac
      done
    }

    # 动态 hugepages 分配（基于 VM XML）
    alloc_hugepages() {
      local xml="$1"
      $XMLLINT --xpath '/domain/memoryBacking/hugepages' - &>/dev/null <<< "$xml" || {
        log "No hugepages config → skip"
        return 0
      }
      local mem_kib=$($XMLLINT --xpath 'string(/domain/memory[1])' - <<< "$xml")
      [[ $mem_kib =~ ^[0-9]+$ ]] || { log "Invalid memory size"; return 1; }
      local pages=$(( mem_kib / 2048 + 64 ))
      log "Requesting $pages hugepages (2MB)"
      for ((i=0; i<1000; i++)); do
        $ECHO "$pages" > /proc/sys/vm/nr_hugepages
        local got=$($CAT /proc/sys/vm/nr_hugepages)
        log "Allocated $got / $pages (try $i)"
        [ "$got" -eq "$pages" ] && { log "Hugepages OK"; return 0; }
        $ECHO 1 > /proc/sys/vm/compact_memory
        $SLEEP 0.05
      done
      log "FAILED → releasing hugepages"
      $ECHO 0 > /proc/sys/vm/nr_hugepages
      return 1
    }

    # 强制杀死所有使用 NVIDIA GPU 的进程
    kill_nvidia_processes() {
      if [ -x "$NVIDIA_SMI" ]; then
        local pids=$($NVIDIA_SMI --query-compute-apps=pid --format=csv,noheader 2>/dev/null)
        for pid in $pids; do
          log "Killing process $pid (using GPU)"
          kill -9 "$pid" 2>/dev/null || true
        done
      else
        log "nvidia-smi not found, skipping process kill"
      fi
      # 额外保险：杀掉所有占用 /dev/nvidia* 的进程
      $FUSER -k /dev/nvidia* 2>/dev/null || true
    }

    # 卸载 NVIDIA 内核模块（顺序很重要）
    unload_nvidia_modules() {
      log "Unloading NVIDIA kernel modules"
      # 尝试卸载，忽略错误，但记录日志
      for mod in nvidia_drm nvidia_modeset nvidia_uvm nvidia; do
        $MODPROBE -r "$mod" 2>/dev/null && log "  $mod unloaded" || log "  $mod unload failed (may already be gone)"
      done
      # 等待 udev 更新
      $SLEEP 1
    }

    # 桌面环境检测（不变）
    need_dm_workaround() {
      case "''${XDG_CURRENT_DESKTOP}" in
        *GNOME*|*KDE*|*COSMIC*|*niri*) return 0 ;;
      esac
      return 1
    }

    # GPU 直通：准备阶段（增强版）
    gpu_prepare() {
      # 1. 检测 NVIDIA 是否存在且被占用
      local nvidia_occupied=false
      # 检查设备节点是否存在
      if [ -e /dev/nvidia0 ] || [ -e /dev/nvidiactl ]; then
        # 优先使用 nvidia-smi 检查是否有计算进程
        if [ -x "$NVIDIA_SMI" ]; then
          local pids=$($NVIDIA_SMI --query-compute-apps=pid --format=csv,noheader 2>/dev/null)
          [ -n "$pids" ] && nvidia_occupied=true
        fi
        # 若 nvidia-smi 未发现进程，再用 fuser 检测是否有其他打开的文件
        if [ "$nvidia_occupied" = false ]; then
          $FUSER /dev/nvidia* >/dev/null 2>&1 && nvidia_occupied=true
        fi
      fi

      # 2. 如果被占用，执行清理（停止DM、解绑控制台、杀进程、卸载模块）
      if [ "$nvidia_occupied" = true ]; then
        log "NVIDIA device is occupied, performing cleanup"

        if need_dm_workaround; then
          log "Stopping display manager (DE requires workaround)"
          $SYSTEMCTL stop display-manager.service
          $SLEEP 3
          $ECHO 0 > /sys/class/vtconsole/vtcon0/bind 2>/dev/null || true
          $ECHO 0 > /sys/class/vtconsole/vtcon1/bind 2>/dev/null || true
          $ECHO efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind 2>/dev/null || true
          $SLEEP 2
        fi

        kill_nvidia_processes
        $SLEEP 1
        unload_nvidia_modules
      else
        log "NVIDIA not present or not occupied, skipping cleanup"
      fi

      # 3. 无论是否占用，都要执行设备分离（直通必须步骤）
      $VIRSH nodedev-detach --device "$1"
      $VIRSH nodedev-detach --device "$2"
      $VIRSH nodedev-detach --device "$3"

      # 4. 如果之前因占用且需要工作区而停止了DM，现在重新启动
      if [ "$nvidia_occupied" = true ] && need_dm_workaround; then
        $SYSTEMCTL start display-manager.service
      fi

      log "GPU detached successfully"
    }

    # GPU 直通：释放阶段（对应调整）
    gpu_release() {
      # 重新加载 NVIDIA 模块（如果之前卸载了），确保主机可用
      $MODPROBE nvidia 2>/dev/null || true

      $VIRSH nodedev-reattach --device "$1"
      $VIRSH nodedev-reattach --device "$2"
      $VIRSH nodedev-reattach --device "$3"

      if need_dm_workaround; then
        $ECHO 1 > /sys/class/vtconsole/vtcon0/bind 2>/dev/null || true
        $ECHO 1 > /sys/class/vtconsole/vtcon1/bind 2>/dev/null || true
        $ECHO efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/bind 2>/dev/null || true
      fi
      $SYSTEMCTL restart systemd-udevd.service systemd-modules-load.service
      $SYSTEMCTL start display-manager.service || true
      log "GPU reattached"
    }
  '';
in {
  imports = [
    ./Oct.nix
    ./Pat.nix
    ./Bazzite.nix
  ];

  environment.etc."libvirt/hooks/common-functions.sh" = {
    text = commonHookFunctions;
    mode = "0555";
  };

  environment = {
    systemPackages = with pkgs; [
      NixVirt.packages.x86_64-linux.default
    ];
  };

  virtualisation.libvirt.enable = true;
  virtualisation.libvirt.verbose = true;
}
