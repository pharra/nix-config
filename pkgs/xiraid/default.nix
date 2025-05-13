{
  lib,
  stdenv,
  python3,
  makeWrapper,
  fetchurl,
  ncurses,
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
  rdma-core,
  ensureNewerSourcesForZipFilesHook,
  fuse3,
  autoPatchelfHook,
  bubblewrap,
}:
stdenv.mkDerivation rec {
  pname = "xiraid";
  version = "1.1.0";

  src = fetchurl {
    url = "https://pkg.xinnor.io/repository/Repository/opus/ver1.1.0/ver1.1.0-e.tgz";
    sha256 = "sha256-RLIBqRl0KEz/fHys/Qjn8Y6ZgXo0yj2zSdvZN+i4Zlk="; # Replace with the actual SHA256 hash of the tarball
  };

  unpackPhase = ''
    tar -xzf $src
    cd ver1.1.0-e
    tar -xzf xiraid.tgz
  '';

  nativeBuildInputs = [autoPatchelfHook makeWrapper];
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
    rdma-core
    fuse3
    python3
    bubblewrap
  ];

  postPatch = ''
    patchShebangs .
  '';

  installPhase = ''
    mkdir -p $out/bin $out/scripts $out/doc $out/python/spdk/rpc

    # 安装二进制
    cp xiraid/bin/xnr_xiraid.1.1.0 $out/bin/
    cp xiraid/bin/xnr_cli.1.1.0 $out/bin/
    cp xiraid/bin/spdk_top $out/bin/

    # 安装脚本
    cp xiraid/scripts/* $out/scripts/

    # 安装文档
    cp xiraid/doc/* $out/doc/

    # 安装 Python 文件
    cp xiraid/python/xnr.py $out/python/
    cp xiraid/python/spdk/*.py $out/python/spdk/ 2>/dev/null || true
    cp xiraid/python/spdk/rpc/*.py $out/python/spdk/rpc/

    # 用 bubblewrap 包裹主程序和 CLI
    makeWrapper ${bubblewrap}/bin/bwrap $out/bin/xnr_xiraid \
      --add-flags "--dev-bind / /" \
      --add-flags "--proc /proc" \
      --add-flags "--tmpfs /tmp" \
      --add-flags "--ro-bind $out/bin/xnr_xiraid.1.1.0 /xnr_xiraid.1.1.0" \
      --add-flags "--setenv PYTHONPATH $out/python" \
      --add-flags "--bind /etc/xiraid/xnr_conf /xnr_conf" \
      --add-flags "/xnr_xiraid.1.1.0"

    makeWrapper ${bubblewrap}/bin/bwrap $out/bin/xnr_cli \
      --add-flags "--dev-bind / /" \
      --add-flags "--proc /proc" \
      --add-flags "--tmpfs /tmp" \
      --add-flags "--ro-bind $out/bin/xnr_cli.1.1.0 /xnr_cli.1.1.0" \
      --add-flags "--setenv PYTHONPATH $out/python" \
      --add-flags "--bind /etc/xiraid/xnr_conf /xnr_conf" \
      --add-flags "/xnr_cli.1.1.0"
  '';

  meta = with lib; {
    description = "xiraid storage software";
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = [];
  };
}
