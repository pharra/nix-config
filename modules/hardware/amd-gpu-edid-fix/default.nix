# 休眠模块：当前没有任何配置引用它（全仓库搜不到），保留待用。
{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.hardware.amd-gpu-edid-fix;

  # 脚本正文在 edid-fix-script.nix（约 255 行 shell + 内嵌 python），避免把 Nix 文件淹没
  edidFixScript = pkgs.writeShellScript "amd-gpu-edid-fix" (import ./edid-fix-script.nix {inherit pkgs;});

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
