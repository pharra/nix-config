{
  lib,
  fetchurl,
  buildLinux,
  ...
} @ args: let
  realtimePatch = rec {
    branch = "6.1";
    kversion = "6.1.54";
    pversion = "rt15";
    name = "rt-${kversion}-${pversion}";
    patch = fetchurl {
      url = "https://www.kernel.org/pub/linux/kernel/projects/rt/${branch}/older/patch-${kversion}-${pversion}.patch.xz";
      sha256 = "cKIh4BcK2hf/iaql2hF9QAgC90HSmGijnEY8GEOLDUY=";
    };
  };
in
  with lib;
    buildLinux (args
      // rec {
        version = "6.1.54";

        # modDirVersion needs to be x.y.z, will automatically add .0 if needed
        modDirVersion = version + "-rt15";

        # branchVersion needs to be x.y
        extraMeta.branch = versions.majorMinor version;

        structuredExtraConfig = with lib.kernel; {
          EXPERT = yes; # PREEMPT_RT depends on it (in kernel/Kconfig.preempt).
          PREEMPT_RT = yes;
          PREEMPT_VOLUNTARY = lib.mkForce no; # PREEMPT_RT deselects it.
          RT_GROUP_SCHED = lib.mkForce (option no); # Removed by sched-disable-rt-group-sched-on-rt.patch.
        };

        kernelPatches = [
          {
            name = "mlx4-kernelPatches";
            patch = ./mlx4.patch;
          }
          {
            name = "acs-kernelPatches";
            patch = ./acs.patch;
          }
          realtimePatch
        ];

        src = fetchurl {
          url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
          sha256 = "oxgeRtQHzWqxX0EkAugiBoT/llmwJit6Pec4RAXOTic=";
        };
      }
      // (args.argsOverride or {}))
