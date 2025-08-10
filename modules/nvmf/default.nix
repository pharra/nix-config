{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.boot.nvmf;
in {
  options.boot.nvmf = with types; {
    enable = mkEnableOption "nvmf initiator to boot from. Note, booting from nvmf. requires networkd based networking.";

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
    boot.initrd = {
      # By default, the stage-1 disables the network and resets the interfaces
      # on startup. Since our startup disks are on the network, we can't let
      # the network not work.
      network.flushBeforeStage2 = false;

      kernelModules = ["nvme-rdma" "nvme-tcp"];

      systemd = {
        initrdBin = [pkgs.nvme-cli];

        services.nixos-nvmf = {
          requiredBy = ["initrd.target"];
          after = ["network-online.target"];
          wants = ["network-online.target"];
          serviceConfig = {
            Type = "simple";
            RemainAfterExit = true;
            ExecStartPre = "${pkgs.nvme-cli}/bin/nvme discover -t ${cfg.type} -a ${cfg.address} -s ${toString cfg.port}";
            ExecStart =
              ["${pkgs.nvme-cli}/bin/nvme connect -t ${cfg.type} -n \"${cfg.target}\" -a ${cfg.address} -s ${toString cfg.port} --reconnect-delay=1 --ctrl-loss-tmo=-1 --fast_io_fail_tmo=0 --keep-alive-tmo=0 --nr-io-queues=16"]
              ++ (
                if cfg.multipath
                then ["${pkgs.nvme-cli}/bin/nvme connect -t ${cfg.type} -n \"${cfg.target}\" -a ${cfg.multiAddress} -s ${toString cfg.port} --reconnect-delay=1 --ctrl-loss-tmo=-1 --fast_io_fail_tmo=0 --keep-alive-tmo=0 --nr-io-queues=16"]
                else []
              );
            ExecStop =
              ["${pkgs.nvme-cli}/bin/nvme disconnect -n \"${cfg.target}\""]
              ++ (
                if cfg.multipath
                then ["${pkgs.nvme-cli}/bin/nvme disconnect -n \"${cfg.target}\""]
                else []
              );
          };
        };

        services.nixos-nvmf-suspend = {
          before = ["systemd-suspend.service"];
          requiredBy = ["systemd-suspend.service"];
          after = ["nvidia-suspend.service"];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.systemd}/bin/systemctl stop nixos-nvmf.service";
          };
        };

        services.nixos-nvmf-hibernate = {
          before = ["systemd-hibernate.service"];
          requiredBy = ["systemd-hibernate.service"];
          after = ["nvidia-hibernate.service"];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.systemd}/bin/systemctl stop nixos-nvmf.service";
          };
        };

        services.nixos-nvmf-resume = {
          after = [
            "systemd-suspend.service"
            "systemd-hibernate.service"
          ];
          requires = ["network-online.target"];
          requiredBy = [
            "systemd-suspend.service"
            "systemd-hibernate.service"
          ];
          before = ["nvidia-resume.service"];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.systemd}/bin/systemctl restart nixos-nvmf.service";
          };
        };
      };
    };
  };
}
