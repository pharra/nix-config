# 存储与备份：ZFS 池、/boot/efi、restic 备份与它的 age 秘密。
# 文件末尾保留了两段被注释掉的 rclone 同步（曾经用过，暂时没启用）。
{
  config,
  lib,
  pkgs,
  mysecrets,
  username,
  ...
}:
with lib; {
  # 使用 ZFS 模块配置基础支持
  services.zfs-config = {
    enable = true;
    hostId = "88fcb8e5";
    poolName = "system";
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  boot.zfs.extraPools = ["data"];
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  age.secrets."restic_password" = {
    file = "${mysecrets}/restic_password.age";
    mode = "777";
    path = "/etc/restic_password";
  };
  age.secrets."rclone_config" = {
    file = "${mysecrets}/rclone_config.age";
    mode = "777";
    path = "/etc/rclone_config.conf";
  };

  services.restic.backups = {
    local_android = {
      user = "wf";
      repository = "/share/restic";
      initialize = true; # initializes the repo, don't set if you want manual control
      passwordFile = config.age.secrets.restic_password.path;
      paths = ["/share/sftp/Android"];
      timerConfig = {
        OnCalendar = "04:00";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };

  # systemd.timers."sync-115" = {
  #   wantedBy = ["timers.target"];
  #   timerConfig = {
  #     OnBootSec = "5m";
  #     OnUnitActiveSec = "6h";
  #     Unit = "sync-115.service";
  #   };
  # };

  # systemd.services."sync-115" = {
  #   script = ''
  #     set -eu
  #     ${pkgs.rclone}/bin/rclone --max-size 1G delete 115:/115open/云下载/share/media --config ${config.age.secrets.rclone_config.path}
  #     ${pkgs.rclone}/bin/rclone copy -Pv --min-size 1G 115:/115open/云下载/share/media /share/media --config ${config.age.secrets.rclone_config.path}
  #   '';
  #   serviceConfig = {
  #     Type = "oneshot";
  #     User = username;
  #   };
  # };

  # systemd.timers."sync-short" = {
  #   wantedBy = ["timers.target"];
  #   timerConfig = {
  #     OnBootSec = "5m";
  #     OnUnitActiveSec = "2h";
  #     Unit = "sync-short.service";
  #   };
  # };

  # systemd.services."sync-short" = {
  #   script = ''
  #     set -eu
  #     ${pkgs.rclone}/bin/rclone --max-size 100M delete 115:/115open/云下载/share/telegram --config ${config.age.secrets.rclone_config.path}
  #     ${pkgs.rclone}/bin/rclone copy -Pv --min-size 100M 115:/115open/云下载/share/telegram /share/telegram --config ${config.age.secrets.rclone_config.path}
  #   '';
  #   serviceConfig = {
  #     Type = "oneshot";
  #     User = username;
  #   };
  # };
}
