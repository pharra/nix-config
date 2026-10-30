# 存储：ZFS 池、/boot/efi。（备份能力已搬到 modules/storage/backup，这里只留一行 enable）
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

  # 备份能力：秘密/服务/定时器都在 modules/storage/backup 里
  services.pharra.backup.enable = true;

  age.secrets."rclone_config" = {
    file = "${mysecrets}/rclone_config.age";
    mode = "777";
    path = "/etc/rclone_config.conf";
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
