# kmscon：跑在 KMS 之上的虚拟终端替代品（真字体、Unicode、颜色，比内核 fbcon 好看）。
#
# 这里刻意关掉硬件渲染（services.kmscon.config.hwaccel = false）：kmscon 的 GL 后端要接
# 显卡的 EGL，在 zed 这种"NVIDIA 专有驱动 + AMD APU"的双 GPU 机器上是已知容易黑屏的组合。
# 纯文本走软件渲染（drm2d 后端）性能差异可以忽略，风险小得多。
#
# 注意：关掉的是 GL，不是 DRM —— kmscon 仍然要拿 DRM master 做 modeset，所以与 Wayland
# compositor 的 VT 切换仍可能出问题。救急办法：**SSH 进去改回**（kmscon 把 logind 的
# autovt@ 别名成了自己，Ctrl+Alt+F3 切出来还是 kmscon，不是内核 fbcon）。
#
# 字体：默认 Sarasa Mono SC（更纱黑体 等宽，1:2 严格等宽，中英文混排对齐）。它来自 nixpkgs 的
# sarasa-gothic 包（1.0.42 起的 TTC 是集合，Mono/Term/Fixed 家族都在里面），不需要自己再打
# 字体包；模块只负责把它装进 fonts.packages 并指定家族名。想要终端专用度更高可换 "Sarasa Term SC"。
{
  config,
  lib,
  pkgs,
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

    fontName = mkOption {
      type = types.str;
      default = "Sarasa Mono SC";
      description = "kmscon 用的字体名（交给 fontconfig 匹配）；默认是带简体中文的等宽字体";
    };

    fontSize = mkOption {
      type = types.ints.positive;
      default = 16;
      description = "字号";
    };
  };

  config = mkIf cfg.enable {
    # 字体跟着能力走：把 nixpkgs 的 sarasa-gothic 装进 fonts.packages（TTC 集合里含 Mono/Term/Fixed），
    # 否则 fontconfig 按名字匹配不到，kmscon 会静默回退到默认字体。
    fonts.packages = [pkgs.sarasa-gothic];

    services.kmscon = {
      enable = true;
      useXkbConfig = true; # 沿用 Wayland/X 的键盘布局（services.xserver.xkb）
      config = {
        hwaccel = false; # 关键：不启用 GL 渲染
        font-name = cfg.fontName;
        font-size = cfg.fontSize;
      };

      extraOptions = concatStringsSep " " (
        ["--term ${cfg.term}"]
        ++ optional (cfg.drmDevice != null) "--drm-device=${cfg.drmDevice}"
      );
    };
  };
}
