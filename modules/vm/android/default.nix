{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib; let
  cfg = config.services.pharra.android;
in {
  options = {
    services.pharra.android = {
      enable = mkEnableOption "Android container";

      enableWaydroidNvidia = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Waydroid with NVIDIA GPU support";
      };

      enableDroidloom = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Droidloom for Android container";
      };

      enableGenymotion = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Genymotion Android emulator";
      };
    };
  };

  config = mkIf cfg.enable {
    # must set zfs set acltype=posixacl ...
    services.waydroid-nvidia = mkIf cfg.enableWaydroidNvidia {
      enable = true;
      refreshRate = 120; # 你的显示器刷新率
    };

    environment.systemPackages = with pkgs;
      [
        android-tools
        scrcpy
      ]
      ++ (
        if cfg.enableGenymotion
        then [genymotion]
        else []
      );

    services.droidloom = mkIf cfg.enableDroidloom {
      enable = true;
      user = username;
      renderNode = "/dev/dri/renderD128";
      gpu = "0000:01:00.0";
      graphicsBackend = "forwarding";
    };
  };
}
