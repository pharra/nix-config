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
}:
stdenv.mkDerivation rec {
  pname = "spdk";
  version = "23.09";

  src = fetchgit {
    url = "https://github.com/spdk/spdk.git";
    rev = "726c8313fd559711a456cae2c335638f31aa79a6";
    fetchSubmodules = true;
    sha256 = "sha256-elwOfO2Bg3r8FRy1fwKAOoPdRdqhd9CjDkmlFNRGr5w=";
  };

  patches = [
    ./setuptools.patch
    ./0001-fix-setuptools-installation.patch
  ];

  nativeBuildInputs = [
    python3
    python3.pkgs.configshell
    python3.pkgs.sphinx
    python3.pkgs.pyelftools
    python3.pkgs.setuptools
    pkg-config
    ensureNewerSourcesForZipFilesHook
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
  ];

  preConfigure = ''
    export AS=nasm
  '';

  postPatch = ''
    patchShebangs .
  '';

  dontUseMesonConfigure = true;
  enableParallelBuilding = true;
  dontUseNinjaBuild = true;
  dontUseNinjaInstall = true;

  configureFlags = ["--with-rdma" "--with-uring" "--with-ublk" "--with-vfio-user" "--with-raid5f" "--pydir=${placeholder "out"}"];

  postInstall = ''
    cp -r scripts $out
  '';
  postCheck = ''
    python3 -m spdk
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
