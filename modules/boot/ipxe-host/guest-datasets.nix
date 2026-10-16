# NFS guest 侧：为每个 guest 建 ZFS 数据集、挂载点并导出 NFS（由 ipxe-host 的 nfs.* 选项驱动）。
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.pharra.ipxe-host;
in {
  config = mkIf cfg.enable {
    system.activationScripts."ipxe-nfs-datasets" = mkIf (cfg.nfs.enable && cfg.nfs.guests != {}) (let
      guestNames = builtins.attrNames cfg.nfs.guests;
      zfsPool = cfg.nfs.zfsPool;
      createDatasetCmds = concatStringsSep "\n" (
        map (
          guestName: ''
            # Create main guest dataset
            if ! zfs list -H -o name "''${pool}/${guestName}" &>/dev/null; then
              echo "Creating ZFS dataset: ''${pool}/${guestName}"
              zfs create "''${pool}/${guestName}"
            fi

            # Create nix dataset
            if ! zfs list -H -o name "''${pool}/${guestName}/nix" &>/dev/null; then
              echo "Creating ZFS dataset: ''${pool}/${guestName}/nix"
              zfs create "''${pool}/${guestName}/nix"
            fi

            # Create nix/persistent dataset
            if ! zfs list -H -o name "''${pool}/${guestName}/nix/persistent" &>/dev/null; then
              echo "Creating ZFS dataset: ''${pool}/${guestName}/nix/persistent"
              zfs create "''${pool}/${guestName}/nix/persistent"
            fi
          ''
        )
        guestNames
      );
    in ''
      set -e
      pool="${zfsPool}"
      PATH=${pkgs.zfs}/bin:$PATH

      # Check if ZFS pool exists
      if ! zfs list "''${pool}" &>/dev/null; then
        echo "Warning: ZFS pool ''${pool} does not exist, skipping dataset creation"
        exit 0
      fi

      ${createDatasetCmds}

      # Create mountpoint directories
      ${concatStringsSep "\n" (
        map (
          guestName: ''
            mkdir -p /${zfsPool}/${guestName}/nix/store
          ''
        )
        guestNames
      )}
    '');

    # Setup bind mounts for /nix/store
    systemd.mounts =
      if cfg.nfs.enable && (cfg.nfs.guests != {})
      then
        map (
          guestName: {
            what = "/nix/store";
            where = "/${cfg.nfs.zfsPool}/${guestName}/nix/store";
            type = "none";
            options = "bind,ro";
            wantedBy = ["local-fs.target"];
          }
        )
        (builtins.attrNames cfg.nfs.guests)
      else [];

    services.nfs = mkIf (cfg.nfs.enable && cfg.nfs.guests != {}) {
      server = {
        enable = true;
        lockdPort = 4001;
        mountdPort = 4002;
        statdPort = 4000;
        exports = concatStringsSep "\n" (
          map (
            guestName: "/${cfg.nfs.zfsPool}/${guestName}/nix *(rw,sync,no_subtree_check,no_root_squash,nohide,insecure,crossmnt)"
          )
          (builtins.attrNames cfg.nfs.guests)
        );
      };
      settings = {
        nfsd.tcp = true;
        nfsd.rdma = true;
        nfsd.vers2 = false;
        nfsd.vers3 = false;
        nfsd.vers4 = true;
      };
    };
    # Load kernel modules for NFS over RDMA
    boot.kernelModules = lib.optionals cfg.nfs.enable ["svcrdma" "xprtrdma"];
  };
}
