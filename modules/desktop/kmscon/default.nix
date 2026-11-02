# kmscon：跑在 KMS 之上的虚拟终端替代品（真字体、Unicode、颜色，比内核 fbcon 好看）。
#
# 这里刻意关掉硬件渲染（services.kmscon.config.hwaccel = false）：kmscon 的 GL 后端要接
# 显卡的 EGL，在 zed 这种"NVIDIA 专有驱动 + AMD APU"的双 GPU 机器上是已知容易黑屏的组合。
# 纯文本走软件渲染（drm2d 后端）性能差异可以忽略，风险小得多。
#
# 注意：关掉的是 GL，不是 DRM —— kmscon 仍然要拿 DRM master 做 modeset，所以与 Wayland
# compositor 的 VT 切换仍可能出问题。救急办法：**SSH 进去改回**（kmscon 把 logind 的
# autovt@ 别名成了自己，Ctrl+Alt+F3 切出来还是 kmscon，不是内核 fbcon）。
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.pharra.kmscon;
in {
  options.services.pharra.kmscon = {
    enable = mkEnableOption "kmscon 虚拟终端（软件渲染）";

    drmDevice = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/dev/dri/card1";
      description = "多 GPU 时显式指定 DRM 设备；null = 用 kmscon 的默认（一般是第一张卡）";
    };

    term = mkOption {
      type = types.str;
      default = "xterm-256color";
      description = "TERM 类型，写进 kmscon 的 --term";
    };
  };

  config = mkIf cfg.enable {
    services.kmscon = {
      enable = true;
      useXkbConfig = true; # 沿用 Wayland/X 的键盘布局（services.xserver.xkb）
      config.hwaccel = false; # 关键：不启用 GL 渲染

      extraOptions = concatStringsSep " " (
        ["--term ${cfg.term}"]
        ++ optional (cfg.drmDevice != null) "--drm-device=${cfg.drmDevice}"
      );
    };
  };
}
