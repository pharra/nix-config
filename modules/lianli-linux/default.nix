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
      (pkgs.writeTextFile {
        name = "lianli-udev-rules";
        destination = "/etc/udev/rules.d/99-lianli.rules";
        text = builtins.readFile (pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/sgtaziz/lian-li-linux/main/udev/99-lianli.rules";
          sha256 = "sha256-r3hqQFonXBQKLl8t23iKWJirHVUyjUCaPjHoVVEtmKM="; # ← 第一次会报错，替换正确 hash
        });
      })
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
