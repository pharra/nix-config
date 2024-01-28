{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.singbox;
in {
  options.services.singbox = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    package = mkOption {
      type = types.package;
      default = pkgs.sing-box;
    };
    settingsFile = mkOption {
      type = types.path;
      default = "/etc/singbox/config.json";
    };
    user = mkOption {
      default = "singbox";
      type = types.str;
    };

    group = mkOption {
      default = "singbox";
      type = types.str;
    };
  };
  config = mkIf cfg.enable {
    systemd.services.singbox = {
      preStart = ''
        mkdir -p /var/lib/sing-box
      '';
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      requires = ["network.target"];
      description = "singbox daemon";
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/sing-box run -D /var/lib/sing-box -c ${cfg.settingsFile}";
        AmbientCapabilities = ["CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" "CAP_SYS_PTRACE" "CAP_DAC_READ_SEARCH"];
        Restart = "on-failure";
        User = cfg.user;
        Group = cfg.group;
      };
    };
    users.users = optionalAttrs (cfg.user == "singbox") {
      singbox = {
        group = cfg.group;
        uid = config.ids.uids.singbox;
      };
    };

    users.groups = optionalAttrs (cfg.group == "singbox") {
      singbox.gid = config.ids.gids.singbox;
    };
  };
}
