{
  lib,
  pkgs,
  config,
  libs,
  ...
}: let
  spdk-iscsi-scripts = pkgs.writeShellScriptBin "spdk-iscsi-scripts" ''
    ${pkgs.spdk}/scripts/rpc.py bdev_aio_create /dev/zvol/data/windata windata
    ${pkgs.spdk}/scripts/rpc.py iscsi_create_initiator_group 1 ANY ANY
    ${pkgs.spdk}/scripts/rpc.py iscsi_create_initiator_group 2 ANY ANY
    ${pkgs.spdk}/scripts/rpc.py iscsi_create_portal_group 1 192.168.29.1:3260
    ${pkgs.spdk}/scripts/rpc.py iscsi_create_portal_group 2 192.168.30.1:3260
    ${pkgs.spdk}/scripts/rpc.py iscsi_create_target_node data data_alias windata:0 '1:1 2:2' 64 -d
  '';

  spdk-nvmf-scripts = pkgs.writeShellScriptBin "spdk-nvmf-scripts" ''
    ${pkgs.spdk}/scripts/rpc.py bdev_aio_create /dev/zvol/data/windata windata
    ${pkgs.spdk}/scripts/rpc.py nvmf_create_transport -t RDMA -u 8192 -i 131072 -c 8192
    ${pkgs.spdk}/scripts/rpc.py nvmf_create_subsystem nqn.2016-06.io.spdk:windata -a -s SPDK00000000000001 -d SPDK_Controller1
    ${pkgs.spdk}/scripts/rpc.py nvmf_subsystem_add_ns nqn.2016-06.io.spdk:windata windata
    ${pkgs.spdk}/scripts/rpc.py nvmf_subsystem_add_listener nqn.2016-06.io.spdk:windata -t rdma -a 192.168.30.1 -s 4420
  '';

  spdk-vhost-scripts = pkgs.writeShellScriptBin "spdk-vhost-scripts" ''
    ${pkgs.spdk}/scripts/rpc.py bdev_aio_create /dev/zvol/zp/microsoft microsoft
    ${pkgs.spdk}/scripts/rpc.py vhost_create_scsi_controller vhost.0
    ${pkgs.spdk}/scripts/rpc.py vhost_scsi_controller_add_target vhost.0 0 microsoft
  '';

  spdk-nvme-scripts = pkgs.writeShellScriptBin "spdk-nvme-scripts" ''
    ${pkgs.kmod}/bin/modprobe ublk_drv
    ${pkgs.spdk}/scripts/rpc.py bdev_nvme_attach_controller -b nvme1 -t pcie -a 0000:81:00.0
    ${pkgs.spdk}/scripts/rpc.py bdev_nvme_attach_controller -b nvme2 -t pcie -a 0000:82:00.0
    ${pkgs.spdk}/scripts/rpc.py bdev_nvme_attach_controller -b nvme3 -t pcie -a 0000:83:00.0
    ${pkgs.spdk}/scripts/rpc.py bdev_nvme_attach_controller -b nvme4 -t pcie -a 0000:84:00.0
    # ${pkgs.spdk}/scripts/rpc.py ublk_create_target
    # ${pkgs.spdk}/scripts/rpc.py ublk_start_disk nvme1n1 1 -q 2 -d 128
    # ${pkgs.spdk}/scripts/rpc.py ublk_start_disk nvme2n1 2 -q 2 -d 128
    # ${pkgs.spdk}/scripts/rpc.py ublk_start_disk nvme3n1 3 -q 2 -d 128
    # ${pkgs.spdk}/scripts/rpc.py ublk_start_disk nvme4n1 4 -q 2 -d 128
  '';

  spdk-scripts = pkgs.writeShellScriptBin "spdk-scripts" ''
    ${pkgs.spdk}/scripts/rpc.py nvmf_create_transport -t VFIOUSER
    ${pkgs.spdk}/scripts/rpc.py bdev_aio_create /dev/mapper/data-microsoft microsoft
    ${pkgs.spdk}/scripts/rpc.py nvmf_create_subsystem nqn.2019-07.io.spdk:microsoft -a -s SPDK0
    ${pkgs.spdk}/scripts/rpc.py nvmf_subsystem_add_ns nqn.2019-07.io.spdk:microsoft microsoft
    ${pkgs.spdk}/scripts/rpc.py nvmf_subsystem_add_listener nqn.2019-07.io.spdk:microsoft -t VFIOUSER -a /var/run -s 0
  '';

  bind-vfio-scripts = pkgs.writeShellScriptBin "bind-vfio-scripts" ''
    echo 0000:81:00.0 > /sys/bus/pci/drivers/nvme/unbind
    echo 0000:82:00.0 > /sys/bus/pci/drivers/nvme/unbind
    echo 0000:83:00.0 > /sys/bus/pci/drivers/nvme/unbind
    echo 0000:84:00.0 > /sys/bus/pci/drivers/nvme/unbind
    ${pkgs.spdk}/scripts/setup.sh
  '';

  unbind-vfio-scripts = pkgs.writeShellScriptBin "unbind-vfio-scripts" ''
    echo 0000:81:00.0 > /sys/bus/pci/drivers/vfio-pci/unbind
    echo 0000:82:00.0 > /sys/bus/pci/drivers/vfio-pci/unbind
    echo 0000:83:00.0 > /sys/bus/pci/drivers/vfio-pci/unbind
    echo 0000:84:00.0 > /sys/bus/pci/drivers/vfio-pci/unbind

    echo 0000:81:00.0 > /sys/bus/pci/drivers/nvme/bind
    echo 0000:82:00.0 > /sys/bus/pci/drivers/nvme/bind
    echo 0000:83:00.0 > /sys/bus/pci/drivers/nvme/bind
    echo 0000:84:00.0 > /sys/bus/pci/drivers/nvme/bind
  '';
in {
  environment.systemPackages = with pkgs; [
    parted
    nvme-cli
    dpdk
    spdk
    openiscsi
    spdk-iscsi-scripts
    spdk-nvmf-scripts
    spdk-vhost-scripts
    spdk-nvme-scripts
    spdk-scripts
    bind-vfio-scripts
    unbind-vfio-scripts
  ];

  systemd.services.spdk = {
    enable = true;
    wantedBy = ["multi-user.target"];
    after = ["rdma.service" "network.target"];
    requires = ["rdma.service"];
    description = "Starts the spdk_tgt";
    path = [pkgs.kmod pkgs.gawk pkgs.util-linux];
    serviceConfig = {
      Type = "simple";
      Environment = "PCI_ALLOWED='none'";
      ExecStartPre = ''
        ${pkgs.spdk}/scripts/setup.sh
        ${pkgs.kmod}/bin/modprobe ublk_drv
      '';
      ExecStart = ''${pkgs.spdk}/bin/spdk_tgt -m 0x30003 -c /home/wf/spdk/rdma_config.json -f /var/run/spdk.pid -S /var/run'';
    };
  };

  # systemd.services.nvmf_tgt = {
  #   enable = true;
  #   wantedBy = ["multi-user.target"];
  #   after = ["rdma.service" "network.target"];
  #   requires = ["rdma.service"];
  #   description = "Starts the nvmf_tgt";
  #   before = ["remote-fs-pre.target"];
  #   unitConfig = {
  #     DefaultDependencies = "no";
  #   };
  #   serviceConfig = {
  #     Type = "simple";
  #     ExecStart = ''${pkgs.spdk}/bin/nvmf_tgt -m 0x02 -r /var/tmp/spdk_nvmf.sock'';
  #   };
  # };

  # systemd.services.iscsi_tgt = {
  #   enable = true;
  #   wantedBy = ["multi-user.target"];
  #   after = ["rdma.service" "network.target"];
  #   requires = ["rdma.service"];
  #   description = "Starts the iscsi_tgt";
  #   before = ["remote-fs-pre.target"];
  #   unitConfig = {
  #     DefaultDependencies = "no";
  #   };
  #   serviceConfig = {
  #     Type = "simple";
  #     ExecStart = ''${pkgs.spdk}/bin/iscsi_tgt -m 0x01'';
  #   };
  # };

  # systemd.services.vhost_tgt = {
  #   enable = true;
  #   wantedBy = ["multi-user.target"];
  #   after = ["rdma.service" "network.target"];
  #   requires = ["rdma.service"];
  #   description = "Starts the vhost_tgt";
  #   before = ["remote-fs-pre.target"];
  #   unitConfig = {
  #     DefaultDependencies = "no";
  #   };
  #   serviceConfig = {
  #     Type = "simple";
  #     ExecStart = ''${pkgs.spdk}/bin/vhost -m 0x04 -r /var/tmp/spdk_vhost.sock -S /var/tmp'';
  #   };
  # };

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
