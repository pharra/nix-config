{
  lib,
  stdenv,
  fetchpatch,
  fetchgit,
  fetchurl,
  ncurses,
  python3,
  cunit,
  libaio,
  libbsd,
  libuuid,
  numactl,
  openssl,
  pkg-config,
  zlib,
  libpcap,
  libnl,
  libelf,
  jansson,
  nasm,
  autoconf269,
  automake,
  libtool,
  liburing,
  json_c,
  cmocka,
  meson,
  ninja,
  rdma-core,
  ensureNewerSourcesForZipFilesHook,
  fuse3,
  fetchFromGitHub,
  autoPatchelfHook,
}:
stdenv.mkDerivation rec {
  pname = "spdk";
  version = "24.01";

  src = fetchFromGitHub {
    owner = "spdk";
    repo = "spdk";
    rev = "v${version}";
    sha256 = "sha256-5znYELR6WvVXbfFKAcRtJnSwAE5WHmA8v1rvZUtszS4=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    python3
    python3.pkgs.configshell
    python3.pkgs.sphinx
    python3.pkgs.pyelftools
    python3.pkgs.setuptools
    python3.pkgs.pip
    python3.pkgs.wheel
    python3.pkgs.wrapPython
    pkg-config
    ensureNewerSourcesForZipFilesHook
    autoPatchelfHook
  ];

  buildInputs = [
    cunit
    libaio
    libbsd
    libuuid
    numactl
    openssl
    ncurses
    pkg-config
    zlib
    libpcap
    libnl
    libelf
    jansson
    nasm
    autoconf269
    automake
    libtool
    liburing
    json_c
    cmocka
    meson
    ninja
    rdma-core
    fuse3
  ];

  preConfigure = ''
    export AS=nasm
  '';

  propagatedBuildInputs = [
    python3.pkgs.configshell
  ];

  postPatch = ''
    patchShebangs .
  '';

  dontUseMesonConfigure = true;
  enableParallelBuilding = true;
  dontUseNinjaBuild = true;
  dontUseNinjaInstall = true;

  configureFlags = ["--with-rdma" "--with-uring" "--with-ublk" "--with-vfio-user" "--with-raid5f"];

  postInstall = ''
    cp -r scripts $out
  '';
  postCheck = ''
    python3 -m spdk
  '';

  postFixup = ''
    wrapPythonPrograms
  '';

  env.NIX_CFLAGS_COMPILE = "-mssse3"; # Necessary to compile.
  # otherwise does not find strncpy when compiling
  NIX_LDFLAGS = "-lbsd";

  meta = with lib; {
    description = "Set of libraries for fast user-mode storage";
    homepage = "https://spdk.io/";
    license = licenses.bsd3;
    platforms = ["x86_64-linux"];
    maintainers = with maintainers; [orivej];
  };
}
