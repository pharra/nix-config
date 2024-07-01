# Derivation for the out-of-tree build of the Linux driver.
{
  lib,
  stdenv,
  kernel, # The Linux kernel Nix package for which this module will be compiled.
  coreutils,
  writeShellScriptBin,
  buildFHSUserEnv,
}: let
  build-scripts = writeShellScriptBin "build-scripts" ''
    ./configure --with-njobs=8 --with-core-mod --with-user_mad-mod --with-user_access-mod --with-addr_trans-mod --with-mlx4-mod --with-mlx4_en-mod --without-mlx5-mod --without-mlx5_core-mod --with-ipoib-mod --with-srp-mod --with-rds-mod --with-iser-mod
    make -j8 kernel
  '';
  buildEnv = buildFHSUserEnv {
    name = "fhs";
    targetPkgs = pkgs: kernel.moduleBuildDependencies ++ [kernel.dev kernel];
    multiPkgs = pkgs: kernel.moduleBuildDependencies ++ [kernel.dev kernel];
    runScript = "${build-scripts}/bin/build-scripts";
    extraBwrapArgs = ["--bind . `pwd`"];
  };
in
  stdenv.mkDerivation {
    pname = "mlnx4-ofed-driver";
    version = "4.9";

    src = builtins.fetchTarball {
      url = "https://content.mellanox.com/ofed/MLNX_OFED-4.9-7.1.0.0/MLNX_OFED_SRC-debian-4.9-7.1.0.0.tgz";
      sha256 = "0cjxbg8hsisrh07j85iqgrjajdy83wn139idwjcscpm9i9p7p4xa";
    };

    nativeBuildInputs = kernel.moduleBuildDependencies;

    dontPatch = true;
    dontConfigure = true;
    dontUpdateAutotoolsGnuConfigScripts = true;

    postUnpack = ''
      tar zxvf source/SOURCES/mlnx-ofed-kernel*
      rm -rf source
      mv mlnx-ofed-kernel* source
    '';

    buildPhase = "${buildEnv}/bin/${buildEnv.name}";

    installPhase = ''
      find .  \( -name "*.ko" -o -name "*.ko.gz" \) -exec install -D {} -t "$out/lib/modules/${kernel.modDirVersion}/kernel/" \;
    '';
  }
