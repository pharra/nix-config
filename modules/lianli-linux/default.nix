{
  config,
  pkgs,
  lib,
  ...
}: {
  options = {
    services.lianli.enable = lib.mkEnableOption "Lian Li Linux control (daemon + GUI)";
  };

  config = lib.mkIf config.services.lianli.enable {
    # === 主程序 ===
    environment.systemPackages = [pkgs.lian-li-linux];

    # === udev rules（必须，让普通用户访问 USB/HID 设备）===
    services.udev.packages = [
      pkgs.lian-li-linux
    ];

    # === 用户级 systemd 服务（lianli-daemon）===
    systemd.user.services.lianli-daemon = {
      description = "Lian Li Linux Daemon";
      wantedBy = ["default.target"];
      after = ["network.target"];

      serviceConfig = {
        ExecStart = "${pkgs.lian-li-linux}/bin/lianli-daemon";
        Restart = "on-failure";
        RestartSec = 3;
        # 推荐不加 --user，因为它是 user service
      };
    };
  };
}
