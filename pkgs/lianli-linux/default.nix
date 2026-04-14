{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  cmake,
  clang,
  hidapi,
  libusb1,
  ffmpeg,
  fontconfig,
  mesa,
  libxkbcommon,
  wayland,
  libx11,
  libxcursor,
  libxrandr,
  libxi,
  libinput,
  libdrm,
  vulkan-loader,
  libGL,
  wayland-scanner, # 重要：Slint/winit 需要
}:
rustPlatform.buildRustPackage rec {
  pname = "lian-li-linux";
  version = "unstable-2026-04-14";

  src = fetchFromGitHub {
    owner = "sgtaziz";
    repo = "lian-li-linux";
    rev = "fe81ca0f69b863c41a06c96481ae1a74c13330e5";
    hash = "sha256-8ioC9U3toMwfhResXPgywhlULbG86byaFtIguhZF1Jc=";
    fetchSubmodules = true;
  };

  cargoHash = "sha256-HxwnENFH3saYxZE5l2hQRXW8MJ3BU1WezRWljJKi82Y=";

  nativeBuildInputs = [
    pkg-config
    cmake
    clang
    wayland-scanner
  ];

  buildInputs = [
    hidapi
    libusb1
    ffmpeg
    fontconfig
    mesa
    libxkbcommon
    wayland
    libx11
    libxcursor
    libxrandr
    libxi
    libinput
    libdrm
    vulkan-loader
    libGL
  ];

  # 关键修复：让 lianli-gui 在运行时能找到 Wayland / EGL / OpenGL 等库
  postFixup = ''
    patchelf --set-rpath "${lib.makeLibraryPath [
      wayland
      libxkbcommon
      mesa
      libGL
      libx11
      libxcursor
      libxrandr
      libxi
      fontconfig
      vulkan-loader
      libdrm
    ]}:$out/lib" \
      $out/bin/lianli-gui 2>/dev/null || true
  '';

  postInstall = ''
    mkdir -p $out/bin \
             $out/share/applications \
             $out/share/icons/hicolor

    # 二进制（workspace build 后在 target/release/ 下）
    cp target/x86_64-unknown-linux-gnu/release/lianli-daemon $out/bin/lianli-daemon || true
    cp target/x86_64-unknown-linux-gnu/release/lianli-gui    $out/bin/lianli-gui    || true

    # desktop 文件
    if [ -f "${src}/com.sgtaziz.lianlilinux.desktop" ]; then
      cp "${src}/com.sgtaziz.lianlilinux.desktop" $out/share/applications/
    fi

    # 图标
    if [ -d "${src}/assets/icons" ]; then
      cp -r "${src}/assets/icons"/* $out/share/icons/hicolor/ 2>/dev/null || true
    fi
  '';

  meta = with lib; {
    description = "Linux replacement for L-Connect 3 (Lian Li fan/RGB/LCD control)";
    homepage = "https://github.com/sgtaziz/lian-li-linux";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "lianli-gui";
  };
}
