{
  lib,
  fetchurl,
  buildLinux,
  ...
} @ args:
with lib;
  buildLinux (args
    // rec {
      version = "6.6.12";

      # modDirVersion needs to be x.y.z, will automatically add .0 if needed
      modDirVersion = versions.pad 3 version;

      # branchVersion needs to be x.y
      extraMeta.branch = versions.majorMinor version;

      kernelPatches = [
        {
          name = "mlx4-kernelPatches";
          patch = ./mlx4.patch;
        }
      ];

      src = fetchurl {
        url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
        sha256 = "sha256-H9fsjD2cTks6QdEeLG0VHl+/h13QizV39zr9buZnRgU=";
      };
    }
    // (args.argsOverride or {}))
