# restic 备份能力：秘密、restic 服务、定时器都归这里。
# 默认值就是 homelab 现在用的那套（仓库 /share/restic、备份 /share/sftp/Android）；
# 别的机器要用就只加一行 services.pharra.backup.enable = true;。
{
  config,
  lib,
  pkgs,
  mysecrets,
  username,
  ...
}:
with lib; let
  cfg = config.services.pharra.backup;
in {
  options.services.pharra.backup = {
    enable = mkEnableOption "restic 备份";

    repository = mkOption {
      type = types.str;
      default = "/share/restic";
      description = "restic 仓库路径（本地目录，或 rclone/sftp 的远端地址）";
    };

    paths = mkOption {
      type = types.listOf types.str;
      default = ["/share/sftp/Android"];
      description = "要备份的路径列表";
    };

    user = mkOption {
      type = types.str;
      default = username;
      description = "备份服务以哪个用户运行（要能读 paths 和密码文件）";
    };

    onCalendar = mkOption {
      type = types.str;
      default = "04:00";
      description = "定时器的 OnCalendar（默认每天凌晨 4 点）";
    };
  };

  config = mkIf cfg.enable {
    # 密码文件由能力自己声明，host 里不用再写
    age.secrets.restic_password = {
      file = "${mysecrets}/restic_password.age";
      mode = "777";
      path = "/etc/restic_password";
    };

    services.restic.backups.local_android = {
      inherit (cfg) user repository paths;
      initialize = true; # 仓库不存在时自动 init
      passwordFile = config.age.secrets.restic_password.path;
      timerConfig = {
        OnCalendar = cfg.onCalendar;
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };
}
