{
  lib,
  pkgs,
  config,
  libs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    parted
    dpdk
    spdk
  ];

  systemd.services.nvmf_tgt = {
    enable = true;
    after = ["rdma.service" "network.target"];
    requires = ["rdma.service"];
    description = "Starts the nvmf_tgt";
    before = ["remote-fs-pre.target"];
    unitConfig = {
      DefaultDependencies = "no";
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = ''${pkgs.spdk}/bin/nvmf_tgt'';
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
}
