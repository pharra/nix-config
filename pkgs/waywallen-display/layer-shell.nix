{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  gettext,
  glslang,
  libglvnd,
  vulkan-headers,
  vulkan-loader,
  wayland,
  makeWrapper,
}:
rustPlatform.buildRustPackage rec {
  pname = "waywallen-display-layer-shell";
  version = "0.4.6";

  src = fetchFromGitHub {
    owner = "waywallen";
    repo = "waywallen-display";
    rev = "v${version}";
    hash = "sha256-N0V/+g81hKJQGN17a9FJAAEeoIP8nZLoLL0655eQyBI=";
  };

  cargoHash = "sha256-nJpt4OLviljzSHQPXtziT+0+jLmOrJ8RXZpIsfHCChk=";
  cargoBuildFlags = [
    "--bin"
    "waywallen-layer-shell"
    "--features"
    "layer-shell"
  ];

  nativeBuildInputs = [
    gettext
    glslang
    makeWrapper
    pkg-config
  ];

  buildInputs = [
    libglvnd
    vulkan-headers
    vulkan-loader
    wayland
  ];

  postInstall = ''
    install -d "$out/share/locale/ru/LC_MESSAGES"
    msgfmt --check --check-format \
      -o "$out/share/locale/ru/LC_MESSAGES/waywallen-layer-shell.mo" \
      "${src}/po/layer-shell/ru.po"

    wrapProgram "$out/bin/waywallen-layer-shell" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
      libglvnd
      vulkan-loader
    ]}"
  '';

  meta = {
    description = "Wayland layer-shell client for waywallen-display";
    homepage = "https://github.com/waywallen/waywallen-display";
    license = lib.licenses.mit;
    mainProgram = "waywallen-layer-shell";
    platforms = lib.platforms.linux;
  };
}
