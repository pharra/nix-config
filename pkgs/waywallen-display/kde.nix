{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  gettext,
  qt6,
  libglvnd,
  vulkan-headers,
  vulkan-loader,
  unzip,
}:
stdenv.mkDerivation rec {
  pname = "waywallen-display-kde";
  version = "0.4.6";

  src = fetchFromGitHub {
    owner = "waywallen";
    repo = "waywallen-display";
    rev = "v${version}";
    hash = "sha256-N0V/+g81hKJQGN17a9FJAAEeoIP8nZLoLL0655eQyBI=";
  };

  nativeBuildInputs = [
    cmake
    gettext
    ninja
    pkg-config
    unzip
  ];

  buildInputs = [
    libglvnd
    qt6.qtbase
    qt6.qtdeclarative
    vulkan-headers
    vulkan-loader
  ];

  cmakeFlags = [
    "-GNinja"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DWAYWALLEN_DISPLAY_PLUGIN_QML=ON"
    "-DWAYWALLEN_DISPLAY_QML_URI=Waywallen.DisplayEmbed"
    "-DWAYWALLEN_DISPLAY_WITH_EGL=ON"
    "-DWAYWALLEN_DISPLAY_WITH_VULKAN=ON"
  ];
  dontWrapQtApps = true;

  buildPhase = ''
    runHook preBuild
    cmake --build . --target package --parallel "$NIX_BUILD_CORES"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -d "$out/share/plasma/wallpapers"
    package=$(find . -type f -name "waywallen-kde-${version}-*.zip" -print -quit)
    if [ -z "$package" ]; then
      echo "Could not find the packaged Waywallen Plasma wallpaper extension" >&2
      exit 1
    fi
    unzip -q "$package" -d "$out/share/plasma/wallpapers"
    test -f "$out/share/plasma/wallpapers/org.waywallen.kde/metadata.json"

    runHook postInstall
  '';

  meta = {
    description = "Waywallen wallpaper extension for KDE Plasma 6";
    homepage = "https://github.com/waywallen/waywallen-display";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
}
