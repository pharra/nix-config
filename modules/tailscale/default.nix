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
        default = pkgs.tailscale;
      };
      listen = mkOption {
        type = types.str;
        default = ":22079";
      };
      httpPort = mkOption {
        type = types.str;
        default = "22079";
      };
      stunPort = mkOption {
        type = types.str;
        default = "3478";
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
      script = "${cfg.package}/bin/derper -a ${cfg.listen} -hostname ${cfg.hostname} --stun-port=${cfg.stunPort} --http-port=${cfg.httpPort} --verify-clients=true";
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [1443];
      allowedUDPPorts = [3478];
    };
  };
}
