{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfgs = config.services.nvme-auto;
in {
  options.services.nvme-auto = with types;
    mkOption {
      description = "List of NVMe devices to connect.";
      type = listOf (submodule {
        options = {
          name = mkOption {
            type = str;
            description = "Service name suffix.";
          };
          multipath = mkEnableOption "enable multipath";
          multiAddress = mkOption {
            type = str;
            default = "";
            description = "Multipath address.";
          };
          address = mkOption {
            type = str;
            default = "192.168.1.1";
            description = "IP address to boot from.";
          };
          port = mkOption {
            type = int;
            default = 4420;
            description = "Port to boot from.";
          };
          target = mkOption {
            type = str;
            default = "";
            description = "Name of the nvmf target to boot from.";
          };
          type = mkOption {
            type = str;
            default = "tcp";
            description = "rdma or tcp";
          };
        };
      });
      default = [];
      example = [
        {
          name = "example";
          address = "192.168.1.1";
          target = "nqn.2016-06.io.spdk:example";
          type = "rdma";
        }
      ];
    };

  config = mkIf (cfgs != []) {
    boot.initrd.kernelModules = ["nvme-rdma" "nvme-tcp"];
    environment.systemPackages = with pkgs; [nvme-cli];

    systemd.services = listToAttrs (map (
        cfg: let
          serviceName = "nvme-auto-${cfg.name}";
        in {
          name = serviceName;
          value = {
            wantedBy = ["multi-user.target"];
            before = ["libvirtd.service"];
            unitConfig = {
              DefaultDependencies = "no";
            };
            wants = ["network-online.target"];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = "yes";
              ExecStartPre = "${pkgs.nvme-cli}/bin/nvme discover -t ${cfg.type} -a ${cfg.address} -s ${toString cfg.port}";
              ExecStart =
                ["${pkgs.nvme-cli}/bin/nvme connect -t ${cfg.type} -n \"${cfg.target}\" -a ${cfg.address} -s ${toString cfg.port} --reconnect-delay=1 --ctrl-loss-tmo=-1 --fast_io_fail_tmo=0 --keep-alive-tmo=0 --nr-io-queues=16"]
                ++ (
                  if cfg.multipath
                  then ["${pkgs.nvme-cli}/bin/nvme connect -t ${cfg.type} -n \"${cfg.target}\" -a ${cfg.multiAddress} -s ${toString cfg.port} --reconnect-delay=1 --ctrl-loss-tmo=-1 --fast_io_fail_tmo=0 --keep-alive-tmo=0 --nr-io-queues=16"]
                  else []
                );
              # ExecStop = "${pkgs.nvme-cli}/bin/nvme disconnect -n \"${cfg.target}\"";
            };
          };
        }
      )
      cfgs);
  };
}
