{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.zfs-config;
in {
  options.services.zfs-config = {
    enable = mkEnableOption "ZFS 文件系统配置";

    poolName = mkOption {
      type = types.str;
      example = "system";
      description = "ZFS 池名称";
    };

    hostId = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "88fcb8e9";
      description = "ZFS 主机 ID (8位十六进制字符串)。如果为 null，则需要在 networking.hostId 中单独配置";
    };

    initrdKernelModules = mkOption {
      type = types.listOf types.str;
      default = ["zfs"];
      description = "initrd 中需要加载的内核模块";
    };
  };

  config = mkIf cfg.enable {
    # 确保 ZFS 内核模块在 initrd 中加载
    boot.initrd.kernelModules = cfg.initrdKernelModules;

    # 确保 ZFS 支持已启用
    boot.supportedFilesystems = ["zfs"];

    # 配置 ZFS 主机 ID（如果提供）
    networking.hostId = mkIf (cfg.hostId != null) cfg.hostId;

    # ZFS 文件系统配置
    fileSystems."/system" = mkDefault {
      device = "${cfg.poolName}";
      fsType = "zfs";
      neededForBoot = true;
      options = ["zfsutil"];
    };

    fileSystems."/tmp" = mkDefault {
      device = "${cfg.poolName}/tmp";
      fsType = "zfs";
      neededForBoot = true;
      options = ["zfsutil"];
    };

    fileSystems."/nix" = mkDefault {
      device = "${cfg.poolName}/nix";
      fsType = "zfs";
      neededForBoot = true;
      options = ["zfsutil"];
    };

    fileSystems."/var" = mkDefault {
      device = "${cfg.poolName}/var";
      fsType = "zfs";
      neededForBoot = true;
      options = ["zfsutil"];
    };

    fileSystems."/nix/var" = mkDefault {
      device = "${cfg.poolName}/nix/var";
      fsType = "zfs";
      neededForBoot = true;
      options = ["zfsutil"];
    };

    fileSystems."/nix/persistent" = mkDefault {
      device = "${cfg.poolName}/nix/persistent";
      fsType = "zfs";
      neededForBoot = true;
      options = ["zfsutil"];
    };
  };
}
