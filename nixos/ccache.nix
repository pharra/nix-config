{
  pkgs,
  lib,
  config,
  utils,
  ...
} @ args: let
  _extraConfig = ''
    export CCACHE_DIR="/var/cache/ccache"
    export CCACHE_SLOPPINESS=random_seed,file_macro,locale,time_macros
    export CCACHE_UMASK=000
  '';

  kernel_cache = pkgs.linuxPackages_latest.kernel.override {
    stdenv = pkgs.ccacheStdenv.override {
      stdenv = pkgs.linuxPackages_latest.kernel.stdenv;
      extraConfig = _extraConfig;
    };
  };
in {
  programs.ccache.enable = true;
  programs.ccache.cacheDir = "/var/cache/ccache";
  # programs.ccache.packageNames = ["linuxPackages_latest.kernel" "linuxPackages_latest.kvmfr"];

  boot = {
    kernelPackages = lib.mkForce (pkgs.linuxPackagesFor kernel_cache);
  };
}
