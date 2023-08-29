{
  lib,
  stdenv,
  fetchpatch,
  fetchgit,
  fetchurl,
  ncurses,
  python3,
  cunit,
  dpdk,
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
}: let
  python3' = python3.withPackages (ps: [
    ps.configshell
  ]);
in
  stdenv.mkDerivation rec {
    pname = "spdk";
    version = "23.05";

    src = fetchgit {
      url = "https://github.com/spdk/spdk.git";
      rev = "396e6facb307e108eb454c9e0769a2b108ff2f0d";
      fetchSubmodules = true;
      sha256 = "sha256-6LDFGI+lD0Ixj8TNW7eNqAcz2ubGRuvMnunDy4qelao=";
    };

    # patches = [
    #   # Backport of upstream patch for ncurses-6.3 support.
    #   # Will be in next release after 21.10.
    #   # ./ncurses-6.3.patch

    #   # DPDK 23.07 compatibility.
    #   (fetchpatch {
    #     url = "https://github.com/spdk/spdk/commit/f72cab94dd35d7b45ec5a4f35967adf3184ca616.patch";
    #     sha256 = "sha256-sSetvyNjlM/hSOUsUO3/dmPzAliVcteNDvy34yM5d4A=";
    #   })
    # ];

    nativeBuildInputs = [
      python3'
    ];

    buildInputs = [
      cunit
      dpdk
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

    enableParallelBuilding = true;

    configureFlags = ["--with-dpdk=${dpdk}" "--with-rdma" "--with-uring"];

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
