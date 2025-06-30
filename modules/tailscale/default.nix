{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.derper;
in {
  options = {
    services.derper = {
      enable = mkEnableOption "Enable derper service";
      hostname = mkOption {
        type = types.str;
      };
      package = mkOption {
        type = types.package;
        default = pkgs.tailscale.derper;
      };
      httpPort = mkOption {
        type = types.int;
        default = 22079;
      };
      stunPort = mkOption {
        type = types.int;
        default = 3478;
      };
      openFirewall = mkOption {
        type = types.bool;
        default = true;
      };
    };
  };

  config = {
    systemd.services.derper = mkIf cfg.enable {
      enable = true;
      description = "tailscale derper server";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "exec";
      };
      script = "${cfg.package}/bin/derper -a :${toString cfg.httpPort} -hostname ${cfg.hostname} --stun-port=${toString cfg.stunPort} --http-port=${toString cfg.httpPort} --verify-clients=true";
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [cfg.httpPort];
      allowedUDPPorts = [cfg.stunPort];
    };
  };
}
