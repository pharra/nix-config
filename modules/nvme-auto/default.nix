{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.nvme-auto;
in {
  options.services.nvme-auto = with types; {
    enable = mkEnableOption "nvme device to connect.";

    multipath = mkEnableOption "enable multipath";

    multiAddress = mkOption {
      description = lib.mdDoc ''
        ip address to boot from.
      '';
      default = "192.168.1.1";
      example = "192.168.1.1";
      type = str;
    };

    address = mkOption {
      description = lib.mdDoc ''
        ip address to boot from.
      '';
      default = "192.168.1.1";
      example = "192.168.1.1";
      type = str;
    };

    port = mkOption {
      description = lib.mdDoc ''
        port to boot from.
      '';
      default = 4420;
      example = 4420;
      type = int;
    };

    target = mkOption {
      description = lib.mdDoc ''
        Name of the nvmf target to boot from.
      '';
      default = null;
      example = "iqn.2020-08.org.linux-nvmf.targethost:example";
      type = nullOr str;
    };

    type = mkOption {
      description = lib.mdDoc ''
        rdma or tcp
      '';
      default = "tcp";
      type = str;
    };
  };

  config = mkIf cfg.enable {
    boot.initrd.kernelModules = ["nvme-rdma" "nvme-tcp"];

    environment.systemPackages = with pkgs; [
      nvme-cli
    ];

    systemd = {
      services.nvme-auto = {
        requiredBy = ["libvirtd.service"];
        before = ["libvirtd.service"];
        after = ["network-online.target"];
        wants = ["network-online.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = "yes";
          ExecStartPre = "${pkgs.nvme-cli}/bin/nvme discover -t ${cfg.type} -a ${cfg.address} -s ${toString cfg.port}";
          ExecStart =
            ["${pkgs.nvme-cli}/bin/nvme connect -t ${cfg.type} -n \"${cfg.target}\" -a ${cfg.address} -s ${toString cfg.port} --reconnect-delay=1 --ctrl-loss-tmo=-1 --fast_io_fail_tmo=0 --keep-alive-tmo=1"]
            ++ (
              if cfg.multipath
              then ["${pkgs.nvme-cli}/bin/nvme connect -t ${cfg.type} -n \"${cfg.target}\" -a ${cfg.multiAddress} -s ${toString cfg.port} --reconnect-delay=1 --ctrl-loss-tmo=-1 --fast_io_fail_tmo=0 --keep-alive-tmo=1"]
              else []
            );
          ExecStop = "${pkgs.nvme-cli}/bin/nvme disconnect -n \"${cfg.target}\"";
        };
      };
    };
  };
}
