# 自建 genymotion 打包，覆盖 nixpkgs 的同名包（见仓库根目录 default.nix + overlay.nix）。
#
# 结构沿用 nixpkgs 的 pkgs/by-name/ge/genymotion/package.nix：用 LD_LIBRARY_PATH 让 nixos 的
# 依赖优先于安装包自带的那份（这些库本机实测没问题）。只多了两处让它在 Wayland 桌面上能正常
# 跑起来的设置。
#
# 1. QT_QPA_PLATFORM=xcb
#    安装包自带 Qt 5.15.2，platforms/ 里只有 libqxcb.so，没有 wayland 插件。本仓库的桌面模块
#    给整个会话设了 QT_QPA_PLATFORM=wayland，不覆盖就直接 abort：
#    "no Qt platform plugin could be initialized ... Available platform plugins are: xcb"。
#
#    为什么不能补 wayland 插件跑原生 Wayland（都试过，不行）：
#    - nixpkgs 的 wayland 插件是 Qt 5.15.19 的，而 Qt 插件要用 libQt5Gui 的*私有* API，私有
#      API 在 patch 版本之间不稳定：实测 5.15.19 的 libQt5WaylandClient 需要
#      _ZTI27QPlatformServiceColorPicker（Qt_5_PRIVATE_API），5.15.2 里没有，加载失败。
#    - 那把整个 Qt 换成 nixpkgs 的 5.15.19 也不行：nixpkgs 没有 Qt5 的 qtwebengine，安装包
#      自带的 libQt5WebEngineCore(5.15.2) 撞上 nix 的 Qt 5.15.19 直接
#      "undefined symbol: _ZdaPvm, version Qt_5"。
#    所以只能走 XWayland。
#
# 2. QT_AUTO_SCREEN_SCALE_FACTOR=0
#    xcb 下 devicePixelRatio 由 Xft.dpi 决定，本仓库给 X11 应用设了 Xft.dpi: 192 → dpr=2。
#    而 player 把设备画面放在 QQuickWidget 里，dpr>1 时那段 GL 渲染会失效：2 倍整窗全黑，
#    1.5 倍上半黑且画面错位。固定在 1 倍渲染就正常了。
{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  # 自带的 qemu 二进制 PT_NOTE 段不连续，稳定版 patchelf 处理不了
  patchelfUnstable,
  which,
  xdg-utils,
  zlib,
  libGL,
  glib,
  libx11,
  libxkbcommon,
  libxrender,
  fontconfig,
  freetype,
  systemdLibs,
  libpulseaudio,
  cairo,
  gdk-pixbuf,
  gtk3,
  pixman,
  # glewinfo 需要
  libxmu,
  libxi,
  libxext,
  nss,
  nspr,
  expat,
  libxcb,
  alsa-lib,
}: let
  packages = [
    stdenv.cc.cc
    zlib
    glib
    libx11
    libxkbcommon
    libxmu
    libxi
    libxext
    libGL
    libxrender
    fontconfig
    freetype
    systemdLibs
    libpulseaudio
    cairo
    gdk-pixbuf
    gtk3
    pixman
    nss
    nspr
    expat
    libxcb
    alsa-lib
  ];
  libPath = lib.makeLibraryPath packages;

  # 见文件头注释 1、2
  wrapArgs = [
    "--set"
    "QT_QPA_PLATFORM"
    "xcb"
    "--set"
    "QT_AUTO_SCREEN_SCALE_FACTOR"
    "0"
    "--unset"
    "QT_PLUGIN_PATH"
    "--unset"
    "QML2_IMPORT_PATH"
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath [xdg-utils])
  ];
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "genymotion";
    version = "3.11.0";

    src = fetchurl {
      url = "https://dl.genymotion.com/releases/genymotion-${finalAttrs.version}/genymotion-${finalAttrs.version}-linux_x64.run";
      name = "genymotion-${finalAttrs.version}-linux_x64.run";
      hash = "sha256-jNcnr0C0N6UGdN9qZqRnFZnJhuo/Ft5j/CG7s5TKBS8=";
    };

    nativeBuildInputs = [
      makeWrapper
      patchelfUnstable
      which
      xdg-utils
    ];

    unpackPhase = ''
      mkdir -p phony-home $out/share/applications
      export HOME=$TMP/phony-home

      mkdir genymotion
      sh $src --yes -d genymotion
      sourceRoot=genymotion

      for desktopFile in genymotion-launchpad genymotion-player; do
        substitute phony-home/.local/share/applications/$desktopFile.desktop \
          $out/share/applications/$desktopFile.desktop \
          --replace-fail "$TMP/genymotion" "$out/libexec"
      done
    '';

    installPhase = ''
      mkdir -p $out/bin $out/libexec
      mv genymotion $out/libexec/
      ln -s $out/libexec/genymotion/{genymotion,player} $out/bin
    '';

    fixupPhase = ''
      patchInterpreter() {
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
          "$out/libexec/genymotion/$1"
      }

      patchExecutable() {
        patchInterpreter "$1"
        wrapProgram "$out/libexec/genymotion/$1" \
          --set "LD_LIBRARY_PATH" "${libPath}" \
          ${lib.escapeShellArgs wrapArgs}
      }

      patchTool() {
        patchInterpreter "tools/$1"
        wrapProgram "$out/libexec/genymotion/tools/$1" \
          --set "LD_LIBRARY_PATH" "${libPath}"
      }

      patchExecutable genymotion
      patchExecutable player
      patchInterpreter qemu/x86_64/bin/qemu-img
      patchInterpreter qemu/x86_64/bin/qemu-system-x86_64

      patchTool adb
      patchTool aapt
      patchTool glewinfo

      # 安装包自带一份 libxkbcommon，会去 /usr/share/X11/xkb 找数据（NixOS 上没有）；
      # 删掉，统一用 nixpkgs 那份（同 nixpkgs 的打包）。
      rm $out/libexec/genymotion/libxkbcommon*
    '';

    meta = {
      description = "Fast and easy Android emulation";
      longDescription = ''
        Genymotion is a relatively fast Android emulator which comes with
        pre-configured Android (x86 with OpenGL hardware acceleration) images,
        suitable for application testing.
      '';
      homepage = "https://www.genymotion.com/";
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux"];
      maintainers = with lib.maintainers; [
        puffnfresh
        ulysseszhan
      ];
      mainProgram = "genymotion";
    };
  })
