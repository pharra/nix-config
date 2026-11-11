{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.pharra.waywallen-layer-shell;
in {
  options.services.pharra.waywallen-layer-shell.enable =
    mkEnableOption "Waywallen layer-shell wallpaper client";

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.waywallen-display-layer-shell];

    systemd.user.services.waywallen-layer-shell = {
      description = "Waywallen layer-shell client";
      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        ExecStart = "${pkgs.waywallen-display-layer-shell}/bin/waywallen-layer-shell";
        Restart = "on-failure";
        RestartSec = 3;
      };
    };
  };
}
