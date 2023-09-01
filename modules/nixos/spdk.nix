{
  lib,
  pkgs,
  config,
  libs,
  ...
}: let
  spdk-iscsi-scripts = pkgs.writeShellScriptBin "spdk-iscsi-scripts" ''
    ${pkgs.spdk}/scripts/rpc.py bdev_uring_create /dev/nbd2 data
    ${pkgs.spdk}/scripts/rpc.py iscsi_create_initiator_group 1 ANY ANY
    ${pkgs.spdk}/scripts/rpc.py iscsi_create_initiator_group 2 ANY ANY
    ${pkgs.spdk}/scripts/rpc.py iscsi_create_portal_group 1 192.168.29.1:3260
    ${pkgs.spdk}/scripts/rpc.py iscsi_create_portal_group 2 192.168.30.1:3260
    ${pkgs.spdk}/scripts/rpc.py iscsi_create_target_node data data_alias data:0 '1:1 2:2' 64 -d
  '';
in {
  environment.systemPackages = with pkgs; [
    parted
    nvme-cli
    dpdk
    spdk
    openiscsi
    spdk-iscsi-scripts
  ];

  systemd.services.nvmf_tgt = {
    enable = true;
    wantedBy = ["multi-user.target"];
    after = ["rdma.service" "network.target"];
    requires = ["rdma.service"];
    description = "Starts the nvmf_tgt";
    before = ["remote-fs-pre.target"];
    unitConfig = {
      DefaultDependencies = "no";
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = ''${pkgs.spdk}/bin/nvmf_tgt -m 0x02 -r /var/tmp/spdk_nvmf.sock'';
    };
  };

  systemd.services.iscsi_tgt = {
    enable = true;
    wantedBy = ["multi-user.target"];
    after = ["rdma.service" "network.target"];
    requires = ["rdma.service"];
    description = "Starts the iscsi_tgt";
    before = ["remote-fs-pre.target"];
    unitConfig = {
      DefaultDependencies = "no";
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = ''${pkgs.spdk}/bin/iscsi_tgt -m 0x01'';
    };
  };

  systemd.services.vhost_tgt = {
    enable = true;
    wantedBy = ["multi-user.target"];
    after = ["rdma.service" "network.target"];
    requires = ["rdma.service"];
    description = "Starts the vhost_tgt";
    before = ["remote-fs-pre.target"];
    unitConfig = {
      DefaultDependencies = "no";
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = ''${pkgs.spdk}/bin/vhost -m 0x04 -r /var/tmp/spdk_vhost.sock'';
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
