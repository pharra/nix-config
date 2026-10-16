# 休眠模块：当前没有任何配置引用它，保留待用。
{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.services.pharra.ddns-go;
  inherit
    (lib)
    mkOption
    types
    mkPackageOption
    mkIf
    ;
in {
  options.services.pharra.ddns-go = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    package = mkPackageOption pkgs "ddns-go" {};
  };
  config = mkIf cfg.enable {
    systemd.services.ddns-go = {
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      description = "ddns-go Daemon";

      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        StateDirectory = "ddns-go";
        ExecStart = "${lib.getExe cfg.package} -c $\{STATE_DIRECTORY}/config.yaml";
        Restart = "on-failure";
      };
    };
  };
}
