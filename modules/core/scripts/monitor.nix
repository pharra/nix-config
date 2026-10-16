# 显示器 EDID / xrandr 相关脚本。
# 字符串连同缩进原样搬过来，所以 Nix 插值与转义语义都不变。
{pkgs}: rec {
  custom_edid = pkgs.runCommand "edid-custom" {} customEdid;

  customEdid = ''
    mkdir -p "$out/lib/firmware/edid"

    # this edid you can copy from your real monitor, check below

    base64 -d > "$out/lib/firmware/edid/custom1.bin" <<'EOF'
    AP///////wAx2DQSAAAAACIaAQOAYDZ4D+6Ro1RMmSYPUFQvzwAxWUVZgYCBQJBAlQCpQLMACOgAMPJwWoCwWIoAwBwyAAAeAAAA/QAYVRiHPAAKICAgICAgAAAA/AB2aXZpZAogICAgICAgAAAAEAAAAAAAAAAAAAAAAAAAAXsCAz/xUWFgX15dEB8EEyIhIAUUAhEBIwkHB4MBAABtAwwAEAAAPCEAYAECA2fYXcQBeAAA4gDK4wUAAOMGAQBN0ACg8HA+gDAgNQDAHDIAAB4aNoCgcDgfQDAgNQDAHDIAABoaHQCAUdAcIECANQDAHDIAABwAAAAAAAAAAAAAgg==
    EOF
  '';

  add = ''
    gpu_vendor="1002:164e"
    gpu_bus_path=`${pkgs.pciutils}/bin/lspci -mm -d $gpu_vendor | ${pkgs.gawk}/bin/awk '{ print $1 }'`
    ${pkgs.coreutils-full}/bin/cat ${custom_edid}/lib/firmware/edid/custom1.bin > /sys/kernel/debug/dri/0000:$gpu_bus_path/DP-2/edid_override
    ${pkgs.coreutils-full}/bin/echo -n "on" | ${pkgs.coreutils-full}/bin/tee /sys/kernel/debug/dri/0000:$gpu_bus_path/DP-2/force
    ${pkgs.coreutils-full}/bin/echo -n "1" | ${pkgs.coreutils-full}/bin/tee /sys/kernel/debug/dri/0000:$gpu_bus_path/DP-2/trigger_hotplug
  '';

  remove = ''
    gpu_vendor="1002:164e"
    gpu_bus_path=`${pkgs.pciutils}/bin/lspci -mm -d $gpu_vendor | ${pkgs.gawk}/bin/awk '{ print $1 }'`
    ${pkgs.coreutils-full}/bin/echo -n "reset" | ${pkgs.coreutils-full}/bin/tee /sys/kernel/debug/dri/0000:$gpu_bus_path/DP-2/edid_override
    ${pkgs.coreutils-full}/bin/echo -n "off" | ${pkgs.coreutils-full}/bin/tee /sys/kernel/debug/dri/0000:$gpu_bus_path/DP-2/force
    ${pkgs.coreutils-full}/bin/echo -n "1" | ${pkgs.coreutils-full}/bin/tee /sys/kernel/debug/dri/0000:$gpu_bus_path/DP-2/trigger_hotplug
  '';
}
