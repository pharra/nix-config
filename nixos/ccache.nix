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

  kernel_cache = pkgs.linuxPackages_6_9.kernel.override {
    stdenv = pkgs.ccacheStdenv.override {
      stdenv = pkgs.linuxPackages_6_9.kernel.stdenv;
      extraConfig = _extraConfig;
    };
  };
in {
  programs.ccache.enable = true;
  programs.ccache.cacheDir = "/var/cache/ccache";

  boot.kernelPackages = lib.mkForce (pkgs.linuxPackagesFor kernel_cache);
}
