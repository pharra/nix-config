{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib; let
  cfg = config.services.pharra.spdk-tgt;
in {
  options = {
    services.pharra.spdk-tgt = {
      enable = mkEnableOption "spdk service";
      coreMask = mkOption {
        type = types.str;
        default = "0x30003";
        description = "spdk_tgt 绑定的 CPU 掩码（-m）";
      };
      configFile = mkOption {
        type = types.str;
        default = "/home/${username}/spdk/rdma_config.json";
        description = "spdk_tgt 的配置文件（-c）";
      };
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
        ExecStart = ''${pkgs.spdk}/bin/spdk_tgt -m ${cfg.coreMask} -c ${cfg.configFile} -f /var/run/spdk.pid -S /var/run'';
      };
    };
  };
}
