{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.hardware.amd-gpu-edid-fix;

  edidFixScript = pkgs.writeShellScript "amd-gpu-edid-fix" ''
        set -x  # 启用命令跟踪

        # 定义 logger 标签
        LOG_TAG="amd-gpu-edid-fix"

        echo "===== AMD GPU EDID Fix Script Starting ====="
        ${pkgs.util-linux}/bin/logger -t "$LOG_TAG" -p user.info "AMD GPU EDID Fix Script Starting"
        echo "DEVPATH: $DEVPATH"
        echo "DEVNAME: $DEVNAME"
        echo "ACTION: $ACTION"
        echo "HOTPLUG: $HOTPLUG"
        ${pkgs.util-linux}/bin/logger -t "$LOG_TAG" -p user.info "Device: DEVPATH=$DEVPATH, ACTION=$ACTION"

        # 从 udev 环境变量获取设备路径
        # DEVPATH 格式如: /devices/pci0000:00/.../drm/card0/card0-DP-5
        if [ -z "$DEVPATH" ]; then
          echo "ERROR: DEVPATH not provided by udev"
          ${pkgs.util-linux}/bin/logger -t "$LOG_TAG" -p user.err "ERROR: DEVPATH not provided by udev"
          exit 1
        fi

        # 提取连接器名称 (例如: card0-DP-5)
        connector=$(${pkgs.coreutils-full}/bin/basename "$DEVPATH")
        echo "Connector: $connector"

        # 提取 card 设备名称 (例如: card0)
        card_device=$(echo "$connector" | ${pkgs.gnused}/bin/sed 's/-.*$//')
        echo "Card device: $card_device"

        # 检查是否是 card 连接器 (格式为 card[0-9]*-*)
        if ! echo "$connector" | ${pkgs.gnugrep}/bin/grep -qE '^card[0-9]+-'; then
          echo "Not a card connector, skipping"
          exit 0
        fi

        # 检查是否是 AMD GPU
        device_path=$(${pkgs.coreutils-full}/bin/readlink -f "/sys/class/drm/$card_device/device")
        vendor=$(${pkgs.coreutils-full}/bin/cat "$device_path/vendor" 2>/dev/null || echo "unknown")
        echo "Vendor ID: $vendor"
        if [ "$vendor" != "0x1002" ]; then
          echo "Skipping: not an AMD GPU"
          ${pkgs.util-linux}/bin/logger -t "$LOG_TAG" -p user.debug "Skipping device $connector: not an AMD GPU (vendor=$vendor)"
          exit 0
        fi

        # 连接器路径
        connector_path="/sys$DEVPATH"
        echo "Connector path: $connector_path"

        # 检查连接状态
        status=$(${pkgs.coreutils-full}/bin/cat "$connector_path/status" 2>/dev/null || echo "unknown")
        echo "Connector status: $status"
        if [ "$status" != "connected" ]; then
          echo "Connector not connected, skipping"
          ${pkgs.util-linux}/bin/logger -t "$LOG_TAG" -p user.debug "Connector $connector not connected, skipping"
          exit 0
        fi

        # 获取显示端口
        display_port=$(echo "$connector" | ${pkgs.gnused}/bin/sed 's/^[^-]*-//')
        echo "Display port: $display_port"

        # 获取 PCI 地址
        pci_path=$(${pkgs.coreutils-full}/bin/basename "$device_path")
        echo "PCI device: $pci_path"

        ${pkgs.util-linux}/bin/logger -t "$LOG_TAG" -p user.info "Processing connected AMD GPU on $connector (PCI: $pci_path, Port: $display_port)"

        # 检查 EDID
        edid_path="$connector_path/edid"
        if [ ! -r "$edid_path" ]; then
          echo "ERROR: EDID not readable at $edid_path"
          ${pkgs.util-linux}/bin/logger -t "$LOG_TAG" -p user.err "ERROR: EDID not readable at $edid_path"
          exit 1
        fi

        edid_size=$(${pkgs.coreutils-full}/bin/wc -c < "$edid_path")
        echo "EDID size: $edid_size bytes"

        if [ "$edid_size" -lt 128 ]; then
          echo "EDID too short, skipping"
          exit 0
        fi

        # 确保 debugfs 已挂载
        if [ ! -d /sys/kernel/debug/dri ]; then
          echo "Mounting debugfs..."
          ${pkgs.util-linux}/bin/mount -t debugfs none /sys/kernel/debug 2>/dev/null || true
        fi

        # 检查 EDID 是否已经被修改过
        echo "Checking if EDID needs modification..."
        ${pkgs.python3}/bin/python3 - "$edid_path" << 'CHECK_EOF'
    import sys

    edid_path = sys.argv[1]

    # 读取 EDID
    with open(edid_path, 'rb') as f:
        d = bytearray(f.read())

    # 检查 vsig_format (byte 24, bits 3-2)
    vsig_format = (d[24] >> 2) & 0x3
    print(f"vsig_format = {vsig_format}", file=sys.stderr)

    # 检查 YCbCr 4:2/4:4 标志 (byte 131, bits 5-4)
    ycbcr_flags = (d[131] >> 4) & 0x3 if len(d) > 131 else -1
    print(f"YCbCr 4:2/4:4 flags = {ycbcr_flags}", file=sys.stderr)

    # 如果两个都是 0，说明已经被修改过了
    if vsig_format == 0 and ycbcr_flags == 0:
        print("INFO: EDID already modified, no need to update", file=sys.stderr)
        sys.exit(0)  # 返回 0 表示已修改，不需要继续
    else:
        sys.exit(1)  # 返回 1 表示需要修改

    CHECK_EOF

        needs_fix=$?
        echo "Modification needed: $needs_fix"

        if [ $needs_fix -eq 0 ]; then
          echo "EDID already has the correct values, skipping"
          ${pkgs.util-linux}/bin/logger -t "$LOG_TAG" -p user.info "EDID on $connector already has correct values, skipping"
          exit 0
        fi

        echo "Applying EDID fix..."
        ${pkgs.util-linux}/bin/logger -t "$LOG_TAG" -p user.notice "Applying EDID fix to $connector"
        ${pkgs.python3}/bin/python3 - "$edid_path" "$pci_path" "$display_port" << 'PYTHON_EOF'
    import sys
    import os
    import subprocess

    edid_path = sys.argv[1]
    pci_path = sys.argv[2]
    display_port = sys.argv[3]

    print(f"\n----- Python EDID Processing Started -----", file=sys.stderr)
    print(f"EDID path: {edid_path}", file=sys.stderr)
    print(f"PCI path: {pci_path}", file=sys.stderr)
    print(f"Display port: {display_port}", file=sys.stderr)

    # 读取原始 EDID
    try:
        with open(edid_path, 'rb') as f:
            d = bytearray(f.read())
        print(f"Successfully read EDID, size: {len(d)} bytes", file=sys.stderr)
    except Exception as e:
        print(f"ERROR: Failed to read EDID: {e}", file=sys.stderr)
        sys.exit(1)

    # 检查 EDID 最小长度
    if len(d) < 128:
        print(f"ERROR: EDID too short ({len(d)} bytes), expected at least 128 bytes", file=sys.stderr)
        print(f"This may indicate the display is not connected or EDID is not available", file=sys.stderr)
        sys.exit(1)

    # 1. 修改 vsig_format (偏移24，bit3-2) 为 0
    old_val = d[24]
    d[24] &= ~0x0C
    print(f"Modified byte 24: 0x{old_val:02x} -> 0x{d[24]:02x}", file=sys.stderr)

    # 2. 修改 YCbCr 4:2/4:4 标志 (偏移131，bit4-5) 为 0
    if len(d) > 131:
        old_val = d[131]
        d[131] &= ~0x30
        print(f"Modified byte 131: 0x{old_val:02x} -> 0x{d[131]:02x}", file=sys.stderr)
    else:
        print(f"EDID too short ({len(d)} bytes), skipping byte 131 modification", file=sys.stderr)

    # 3. 修改显示器名称 - 从原 EDID 读取，后缀添加 "RGB"
    # 首先找到并读取现有的显示器名称
    original_name = ""
    name_desc_pos = -1
    for desc in range(54, 126, 18):
        if desc + 3 < len(d) and d[desc + 3] == 0xFC:
            start = desc + 5
            if start + 13 <= len(d):
                original_name = d[start:start+13].decode("ascii").rstrip()
                name_desc_pos = start
                print(f"Found original monitor name: '{original_name}'", file=sys.stderr)
                break

    # 构建新名称：原名称 + "RGB"，总长度不超过13字符
    # 如果原名称超过10个字符，截断到10个字符
    if len(original_name) > 10:
        original_name = original_name[:10]
        print(f"Truncated monitor name to 10 chars: '{original_name}'", file=sys.stderr)

    target = (original_name + "RGB").ljust(13)
    print(f"New monitor name: '{target.rstrip()}'", file=sys.stderr)

    # 如果找到了名称描述符，更新它
    if name_desc_pos != -1:
        d[name_desc_pos:name_desc_pos+13] = target.encode("ascii")
    else:
        print("Warning: Monitor name descriptor not found", file=sys.stderr)

    # 4. 重新计算所有128字节块的校验和
    print(f"Recalculating checksums for {len(d)//128} blocks", file=sys.stderr)
    for block in range(0, len(d), 128):
        old_checksum = d[block+127]
        s = sum(d[block:block+127]) % 256
        d[block+127] = (256 - s) % 256
        print(f"Block {block//128}: checksum 0x{old_checksum:02x} -> 0x{d[block+127]:02x}", file=sys.stderr)

    # 5. 写入 EDID override
    debug_path = f"/sys/kernel/debug/dri/{pci_path}/{display_port}/edid_override"
    print(f"\nTarget debug path: {debug_path}", file=sys.stderr)

    # 检查目录是否存在
    debug_dir = os.path.dirname(debug_path)
    if not os.path.exists(debug_dir):
        print(f"ERROR: Debug directory does not exist: {debug_dir}", file=sys.stderr)
        print(f"Available paths in /sys/kernel/debug/dri/{pci_path}/:", file=sys.stderr)
        try:
            for item in os.listdir(f"/sys/kernel/debug/dri/{pci_path}/"):
                print(f"  - {item}", file=sys.stderr)
        except Exception as e:
            print(f"Could not list directory: {e}", file=sys.stderr)
        sys.exit(1)

    try:
        with open(debug_path, 'wb') as f:
            bytes_written = f.write(d)
        print(f"Successfully wrote {bytes_written} bytes to {debug_path}", file=sys.stderr)

        # 触发热拔插以重新读取 EDID
        hotplug_path = f"/sys/kernel/debug/dri/{pci_path}/{display_port}/trigger_hotplug"
        print(f"Triggering hotplug on {hotplug_path}", file=sys.stderr)
        try:
            with open(hotplug_path, 'w') as f:
                f.write("1")
            print("Hotplug triggered successfully", file=sys.stderr)
        except Exception as e:
            print(f"Warning: Failed to trigger hotplug: {e}", file=sys.stderr)
    except PermissionError:
        print(f"ERROR: Permission denied writing to {debug_path}", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print(f"ERROR: Debug path not found: {debug_path}", file=sys.stderr)
        sys.exit(1)

    PYTHON_EOF

        fix_result=$?
        echo ""
        if [ $fix_result -eq 0 ]; then
          echo "===== AMD GPU EDID fix completed successfully for $connector ====="
          ${pkgs.util-linux}/bin/logger -t "$LOG_TAG" -p user.notice "EDID fix completed successfully for $connector"
        else
          echo "===== AMD GPU EDID fix FAILED for $connector ====="
          ${pkgs.util-linux}/bin/logger -t "$LOG_TAG" -p user.err "EDID fix FAILED for $connector (exit code: $fix_result)"
        fi
  '';

  # udev 规则：精确响应显示器热插拔事件
  udevRule = ''
    # 热插拔事件：当连接器状态改变时触发（包括手动触发和真实热插拔）
    ACTION=="change", SUBSYSTEM=="drm", KERNEL=="card[0-9]*-*", RUN+="${edidFixScript}"
  '';
in {
  options.hardware.amd-gpu-edid-fix = {
    enable =
      mkEnableOption "AMD GPU EDID fix for display color gamut"
      // {
        description = ''
          Automatically fix AMD GPU display color gamut issues by modifying EDID.
          The fix will be applied automatically when displays are hot-plugged on any AMD GPU.
        '';
      };
  };

  config = mkIf cfg.enable {
    # udev 规则：在显示器热插拔时自动运行脚本
    services.udev.extraRules = udevRule;

    # systemd service：在启动时触发 EDID 修复
    systemd.services.amd-gpu-edid-fix-boot = {
      description = "AMD GPU EDID Fix - Boot Trigger";
      documentation = ["man:udevadm(8)"];

      # 在 display manager 启动之后运行
      after = ["display-manager.service"];
      wants = ["display-manager.service"];

      # 仅在启动时运行一次
      unitConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/udevadm trigger --subsystem-match=drm --action=change";
        StandardOutput = "journal";
        StandardError = "journal";
      };

      wantedBy = ["multi-user.target"];
    };

    # 确保 debugfs 被挂载
    boot.kernelParams = ["debugfs"];
  };
}
