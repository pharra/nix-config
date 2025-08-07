# This file describes your repository contents.
# It should return a set of nix derivations
# and optionally the special attributes `lib`, `modules` and `overlays`.
# It should NOT import <nixpkgs>. Instead, you should take pkgs as an argument.
# Having pkgs default to <nixpkgs> is fine though, and it lets you use short
# commands such as:
#     nix-build -A mypackage
{pkgs ? import <nixpkgs> {}}: let
  linux_mlx = pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor (pkgs.callPackage ./pkgs/linux {}));
  spdk_pkgs = pkgs.callPackage ./pkgs/spdk {};
in rec {
  # The `lib`, `modules`, and `overlay` names are special
  # lib = import ./lib {inherit pkgs;}; # functions
  # modules = import ./modules; # NixOS modules
  overlays = import ./overlays; # nixpkgs overlays

  inherit linux_mlx;
  spdk = spdk_pkgs.spdk;
  distrobox-session = pkgs.callPackage ./pkgs/distrobox {};
  spdk-python = spdk_pkgs.spdk-python;
  xiraid = pkgs.callPackage ./pkgs/xiraid {};
  mcontrolcenter = pkgs.libsForQt5.callPackage ./pkgs/mcontrolcenter/default.nix {};
  caddy = pkgs.callPackage ./pkgs/caddy {};
  sub-store-cli = pkgs.callPackage ./pkgs/sub-store-cli {};
  aosp = pkgs.callPackage ./pkgs/aosp {};
  mlnx_ofed = pkgs.callPackage ./pkgs/mlnx_ofed {kernel = pkgs.linuxPackages_latest.kernel;};
  mlnx4_ofed = pkgs.callPackage ./pkgs/mlnx4_ofed {kernel = pkgs.linuxPackages_5_15.kernel;};
  surface-dtx-daemon = pkgs.callPackage ./pkgs/surface-dtx-daemon {};
}
