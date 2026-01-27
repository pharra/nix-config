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
    virtualisation.waydroid.enable = true;

    environment.systemPackages = with pkgs; [
      android-tools
      scrcpy
      python3
    ];
  };
}
