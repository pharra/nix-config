# This file describes your repository contents.
# It should return a set of nix derivations
# and optionally the special attributes `lib`, `modules` and `overlays`.
# It should NOT import <nixpkgs>. Instead, you should take pkgs as an argument.
# Having pkgs default to <nixpkgs> is fine though, and it lets you use short
# commands such as:
#     nix-build -A mypackage
{pkgs ? import <nixpkgs> {}}: let
  spdk_pkgs = pkgs.callPackage ./pkgs/spdk {};
in rec {
  spdk = spdk_pkgs.spdk;
  distrobox-session = pkgs.callPackage ./pkgs/distrobox {};
  spdk-python = spdk_pkgs.spdk-python;
  xiraid = pkgs.callPackage ./pkgs/xiraid {};
  aosp = pkgs.callPackage ./pkgs/aosp {};
  surface-dtx-daemon = pkgs.callPackage ./pkgs/surface-dtx-daemon {};
  audio-relay = pkgs.callPackage ./pkgs/audiorelay {};
}
