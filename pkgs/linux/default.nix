{
  lib,
  fetchurl,
  buildLinux,
  ...
} @ args:
with lib;
  buildLinux (args
    // rec {
      version = "6.6.7";

      # modDirVersion needs to be x.y.z, will automatically add .0 if needed
      modDirVersion = versions.pad 3 version;

      # branchVersion needs to be x.y
      extraMeta.branch = versions.majorMinor version;

      kernelPatches = [
        {
          name = "mlx4-kernelPatches";
          patch = ./mlx4.patch;
        }
        {
          name = "acs-kernelPatches";
          patch = ./acs.patch;
        }
      ];

      src = fetchurl {
        url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
        sha256 = "sha256-DOaOxgGQGRQAQyY1IJVezQSDnlWhuqsvqRVbQrtv2EE=";
      };
    }
    // (args.argsOverride or {}))
