{
  pkgs,
  buildFHSEnv,
  stdenv,
}: let
  fhs = buildFHSEnv {
    name = "android-env";
    targetPkgs = pkgs: (with pkgs; [
      git
      gitRepo
      gnupg
      curl
      procps
      openssl
      gnumake
      nettools
      android-tools
      jdk
      schedtool
      util-linux
      m4
      gperf
      perl
      libxml2
      zip
      unzip
      bison
      flex
      lzop
      python3
      ccache
    ]);
    multiPkgs = pkgs: (with pkgs; [
      zlib
      ncurses5
    ]);
    runScript = "bash";
    profile = ''
      export ALLOW_NINJA_ENV=true
      export USE_CCACHE=1
      export CCACHE_DIR=/data/aosp/ccache
      export ANDROID_JAVA_HOME=${pkgs.jdk.home}
      export LD_LIBRARY_PATH=/usr/lib:/usr/lib32
    '';
  };
in
  pkgs.writeShellScriptBin "android-fhs-env" ''exec ${fhs}/bin/android-env''
