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
}:
stdenv.mkDerivation rec {
  pname = "spdk";
  version = "23.05";

  src = fetchgit {
    url = "https://github.com/spdk/spdk.git";
    rev = "a1f4f11b41e4fa9fe9242fa8467a3eee92c20a03";
    fetchSubmodules = true;
    sha256 = "sha256-nfHW/oXEzSQ4FmXervDG5+E6OP40MWiXy17Ey1GAehQ=";
  };

  patches = [
    ./python-setup.patch
  ];

  nativeBuildInputs = [
    python3
    python3.pkgs.configshell
    python3.pkgs.sphinx
    python3.pkgs.pyelftools
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

    # glibc-2.36 adds arc4random, so we don't need the custom implementation
    # here anymore. Fixed upstream in https://github.com/spdk/spdk/commit/43a3984c6c8fde7201d6c8dfe1b680cb88237269,
    # but the patch doesn't apply here.
    sed -i -e '1i #define HAVE_ARC4RANDOM 1' lib/iscsi/iscsi.c
  '';

  dontUseMesonConfigure = true;
  enableParallelBuilding = true;
  dontUseNinjaBuild = true;
  dontUseNinjaInstall = true;

  configureFlags = ["--with-rdma" "--with-uring" "--with-ublk" "--with-vfio-user" "--with-raid5f"];

  postInstall = ''
    cp -r scripts $out
    cp -r python/spdk $out/scripts
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
