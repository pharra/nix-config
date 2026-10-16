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
      type = with types;
        listOf (submodule {
          options = {
            number = mkOption {
              type = int;
            };
            name = mkOption {
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
