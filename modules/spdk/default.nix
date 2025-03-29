{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.spdk;
in {
  options = {
    services.spdk = {
      enable = mkEnableOption "spdk service";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.spdk];

    systemd.services.spdk = {
      enable = true;
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      requires = ["network.target"];
      description = "Starts the spdk_tgt";
      path = [pkgs.kmod pkgs.gawk pkgs.util-linux];
      serviceConfig = {
        Type = "simple";
        Environment = "PCI_ALLOWED='none'";
        ExecStartPre = [
          "${pkgs.spdk}/scripts/setup.sh"
          #"${pkgs.kmod}/bin/modprobe ublk_drv"
        ];
        ExecStart = ''${pkgs.spdk}/bin/spdk_tgt -m 0x30003 -c /home/wf/spdk/rdma_config.json -f /var/run/spdk.pid -S /var/run'';
      };
    };

    security.pam.loginLimits = [
      {
        domain = "*";
        item = "memlock";
        type = "soft";
        value = "unlimited";
      }
      {
        domain = "*";
        item = "memlock";
        type = "hard";
        value = "unlimited";
      }
      {
        domain = "root";
        item = "memlock";
        type = "soft";
        value = "unlimited";
      }
      {
        domain = "root";
        item = "memlock";
        type = "hard";
        value = "unlimited";
      }
    ];
  };
}
