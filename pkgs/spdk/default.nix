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
}: let
  src = fetchFromGitHub {
    owner = "spdk";
    repo = "spdk";
    rev = "bc6e91d14fb2f1a4b0d14ea28b6ac807681623e5";
    sha256 = "sha256-UCuMkIvsDT8il/WsY6f6LaTE6j4YZu5aXfPEY2WIRH4=";
    fetchSubmodules = true;
  };
in {
  spdk = stdenv.mkDerivation rec {
    pname = "spdk";
    version = "25.05";

    inherit src;

    nativeBuildInputs = [
      python3
      python3.pkgs.configshell-fb
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
      python3.pkgs.configshell-fb
    ];

    patches = [
      # Fixes build with isa-l-crypto.
      ./isa-l-crypto.diff
      ./disable-python.diff
      ./fix-spdk_top.diff
    ];

    postPatch = ''
      patchShebangs .
    '';

    dontUseMesonConfigure = true;
    enableParallelBuilding = true;
    dontUseNinjaBuild = true;
    dontUseNinjaInstall = true;

    configureFlags = ["--with-rdma" "--with-uring"];
    #configureFlags = ["--with-rdma" "--with-uring" "--with-ublk" "--with-vfio-user" "--with-raid5f"];

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
  };

  spdk-python = python3.pkgs.buildPythonApplication rec {
    pname = "spdk-python";
    version = "25.05";
    pyproject = true;

    inherit src;

    preConfigure = ''
      cd python
      echo -n "__version__ = '25.9rc0'" > spdk/version.py
    '';

    build-system = with python3.pkgs; [
      setuptools
      hatchling
    ];

    dependencies = with python3.pkgs; [
      configshell-fb
      sphinx
      pyelftools
      setuptools
      wheel
    ];

    meta = with lib; {
      description = "Set of libraries for fast user-mode storage";
      homepage = "https://spdk.io/";
      license = licenses.bsd3;
      platforms = ["x86_64-linux"];
      maintainers = with maintainers; [orivej];
    };
  };
}
