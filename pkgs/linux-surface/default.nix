{
  lib,
  fetchurl,
  buildLinux,
  fetchFromGitHub,
  pkgs,
  ...
} @ args: let
  version = "6.10.10";
  linux-surface = fetchFromGitHub {
    owner = "linux-surface";
    repo = "linux-surface";
    rev = "arch-6.10.10-1";
    hash = "sha256-AX48oDmzzEoYQkCmF/201opXuVofwGMUI9qvRt+YVHc=";
  };
  surfacePatches = {
    patchSrc ? (linux-surface + "/patches/${lib.versions.majorMinor version}"),
    version,
    patchFn,
  }:
    pkgs.callPackage patchFn {
      inherit (lib) kernel;
      inherit version patchSrc;
    };
  kernelPatches = surfacePatches {
    inherit version;
    patchFn = ./patches.nix;
  };
in
  with lib;
    buildLinux (args
      // rec {
        inherit version kernelPatches;
        # modDirVersion needs to be x.y.z, will automatically add .0 if needed
        modDirVersion = versions.pad 3 version;

        # branchVersion needs to be x.y
        extraMeta.branch = versions.majorMinor version;

        src = fetchurl {
          url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
          sha256 = "sha256-5ofnNbXrnvttZ7QkM8k/yRGBBqmVUU8GJlKHO16Am80=";
        };
      }
      // (args.argsOverride or {}))
