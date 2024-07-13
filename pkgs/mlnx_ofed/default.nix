# Derivation for the out-of-tree build of the Linux driver.
{
  lib,
  stdenv,
  kernel, # The Linux kernel Nix package for which this module will be compiled.
  coreutils,
  writeShellScriptBin,
  buildFHSUserEnv,
  xz,
}: let
  build-scripts = writeShellScriptBin "build-scripts" ''
    ./configure --with-njobs=8 --with-core-mod --with-user_mad-mod --with-user_access-mod --with-addr_trans-mod --with-mlx5-mod --with-ipoib-mod --with-srp-mod --with-iser-mod
    make -j8
    find .  \( -name "*.ko" \) -exec xz {} \;
  '';
  buildEnv = buildFHSUserEnv {
    name = "fhs";
    targetPkgs = pkgs: kernel.moduleBuildDependencies ++ [kernel.dev kernel xz];
    multiPkgs = pkgs: kernel.moduleBuildDependencies ++ [kernel.dev kernel xz];
    runScript = "${build-scripts}/bin/build-scripts";
    extraBwrapArgs = ["--bind . `pwd`"];
  };
in
  stdenv.mkDerivation {
    pname = "mlnx-ofed-driver";
    version = "0.6.6.0";

    src = builtins.fetchTarball {
      url = "https://content.mellanox.com/ofed/MLNX_OFED-24.04-0.6.6.0/MLNX_OFED_SRC-debian-24.04-0.6.6.0.tgz";
      sha256 = "12rkxavpwmg00283hpgcy8a2l0ivq4j9kcpif25h2pas99jdkvhq";
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

    # preConfigure = ''
    #   function patch_dir(){
    #       for file in `ls $1`; do
    #           echo $1"/"$file
    #           if [ -d $1"/"$file ]; then
    #               patch_dir $1"/"$file
    #           else
    #               sed -i $1"/"$file -e 's|/bin/rm|rm|'
    #               sed -i $1"/"$file -e 's|/bin/mktemp|mktemp|'
    #               sed -i $1"/"$file -e 's|/bin/cp|cp|'
    #               sed -i $1"/"$file -e 's|/bin/mkdir|mkdir|'
    #               sed -i $1"/"$file -e 's|/bin/cat|cat|'
    #               sed -i $1"/"$file -e 's|/sbin/depmod|depmod|'
    #               sed -i $1"/"$file -e 's|/bin/ls|ls|'
    #               sed -i $1"/"$file -e 's|/bin/ls|ls|'
    #           fi
    #       done
    #   }

    #   patch_dir .
    #   patchShebangs .
    # '';

    # configureScript = "./configure";

    # configureFlags = [
    #   "--with-core-mod"
    #   "--with-user_mad-mod"
    #   "--with-user_access-mod"
    #   "--with-addr_trans-mod"
    #   "--with-mlx4-mod"
    #   "--with-mlx4_en-mod"
    #   "--with-mlx5-mod"
    #   "--with-ipoib-mod"
    #   "--with-srp-mod"
    #   "--with-rds-mod"
    #   "--with-iser-mod"
    #   "--kernel-sources=${kernel.dev}/lib/modules/${kernel.modDirVersion}/source"
    #   "--with-linux=${kernel.dev}/lib/modules/${kernel.modDirVersion}/source"
    #   "--with-linux-obj=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    #   "--modules-dir=${kernel.dev}/lib/modules/${kernel.modDirVersion}"
    #   "--kernel-version=${kernel.version}"
    # ];

    buildPhase = "${buildEnv}/bin/${buildEnv.name}";

    installPhase = ''
      find .  \( -name "*.ko.xz" \) -exec install -D {} -T $out/lib/modules/${kernel.modDirVersion}/kernel/{} \;
    '';
  }
