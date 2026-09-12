{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.pharra.waydroid;
in {
  options = {
    services.pharra.waydroid = {
      enable = mkEnableOption "waydroid Android container";
    };
  };

  config = mkIf cfg.enable {
    # must set zfs set acltype=posixacl ...
    services.waydroid-nvidia.enable = true;
    services.waydroid-nvidia.refreshRate = 120; # 你的显示器刷新率

    environment.systemPackages = with pkgs; [
      android-tools
      scrcpy
      # genymotion
    ];
  };
}
