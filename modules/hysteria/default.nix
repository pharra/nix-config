{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.hysteria;
in {
  options.services.hysteria = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    package = mkOption {
      type = types.package;
      default = pkgs.hysteria;
    };
    settingsFile = mkOption {
      type = types.path;
      default = "/etc/hysteria/config.yaml";
    };
    user = mkOption {
      default = "hysteria";
      type = types.str;
    };

    group = mkOption {
      default = "hysteria";
      type = types.str;
    };
  };
  config = mkIf cfg.enable {
    systemd.services.hysteria = {
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      requires = ["network.target"];
      description = "hysteria daemon";
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/hysteria server -c ${cfg.settingsFile}";
        AmbientCapabilities = ["CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE"];
        Restart = "on-failure";
        User = cfg.user;
        Group = cfg.group;
      };
    };
    users.users = optionalAttrs (cfg.user == "hysteria") {
      hysteria = {
        group = cfg.group;
        uid = config.ids.uids.hysteria;
      };
    };

    users.groups = optionalAttrs (cfg.group == "hysteria") {
      hysteria.gid = config.ids.gids.hysteria;
    };
  };
}
