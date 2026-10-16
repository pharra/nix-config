{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.hardware.net-sriov;
in {
  options.hardware.net-sriov = {
    enable = mkEnableOption "Enable Net SR-IOV";

    interfaces = lib.mkOption {
      description = "要开启 SR-IOV 的网卡列表";
      type = with types;
        listOf (submodule {
          options = {
            number = mkOption {
              description = "这个网卡上要开出的 VF 数量";
              type = int;
            };
            name = mkOption {
              description = "网卡名，用于生成 systemd 单元";
              type = str;
            };
          };
        });
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services =
      foldl' (
        services: interface: let
          name = interface.name;
          number = interface.number;
        in
          services
          // {
            "${name}-sriov" = {
              enable = true;
              script = "set -e\n" + "echo ${toString number} | tee /sys/class/net/${name}/device/sriov_numvfs";
              wantedBy = ["network.target"];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = "yes";
              };
            };
          }
      ) {}
      cfg.interfaces;
  };
}
