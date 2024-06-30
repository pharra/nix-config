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
    # The "scripted" networking configuration (ie: non-networkd)
    # doesn't properly order the start and stop of the interfaces, and the
    # network interfaces are torn down before unmounting disks. Since this
    # module is specifically for very-early-boot network mounts, we need
    # the network to stay on.
    #
    # We could probably fix the scripted options to properly order, but I'm
    # not inclined to invest that time today. Hopefully this gets users far
    # enough along and they can just use networkd.
    networking.useNetworkd = true;
    networking.useDHCP = false; # Required to set useNetworkd = true

    boot.initrd = {
      # By default, the stage-1 disables the network and resets the interfaces
      # on startup. Since our startup disks are on the network, we can't let
      # the network not work.
      network.flushBeforeStage2 = false;

      kernelModules = ["nvme-rdma" "nvme-tcp"];

      systemd = {
        packages = [pkgs.nvme-cli];

        services.nixos-nvmf = {
          requiredBy = ["initrd.target"];
          after = ["network-online.target"];
          wants = ["network-online.target"];
          serviceConfig = {
            Type = "oneshot";
            ExecStartPre = "${pkgs.nvme-cli}/bin/nvme discover -t ${cfg.type} -a ${cfg.address} -s ${toString cfg.port} -Q 1024 -l 3600";
            ExecStart =
              ["${pkgs.nvme-cli}/bin/nvme connect -t ${cfg.type} -n \"${cfg.target}\" -a ${cfg.address} -s ${toString cfg.port} -Q 1024 -l 3600"]
              ++ (
                if cfg.multipath
                then ["${pkgs.nvme-cli}/bin/nvme connect -t ${cfg.type} -n \"${cfg.target}\" -a ${cfg.multiAddress} -s ${toString cfg.port} -Q 1024 -l 3600"]
                else []
              );
          };
        };
      };
    };
  };
}
