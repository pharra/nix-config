{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.mcontrolcenter;
in {
  options = {
    programs.mcontrolcenter = {
      enable = mkEnableOption "msi control center";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.makeAutostartItem {
        name = "MControlCenter";
        package = pkgs.mcontrolcenter;
      })
    ];

    boot.kernelModules = ["ec_sys"];
    boot.extraModprobeConfig = "options ec_sys write_support=1";
  };
}
