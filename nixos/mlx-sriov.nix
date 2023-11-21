{
  lib,
  pkgs,
  config,
  ...
}: let
  opensm-launch = pkgs.writeShellScriptBin "opensm.launch" ''
    (while true; do ${pkgs.opensm}/bin/opensm; sleep 30; done) &
    exit 0
  '';
in {
  # boot.initrd.kernelModules = [
  #   # These modules are loaded by the system if any InfiniBand device is installed
  #   # InfiniBand over IP netdevice
  #   "ib_ipoib"

  #   # Access to fabric management SMPs and GMPs from userspace.
  #   "ib_umad"

  #   # SCSI Remote Protocol target support
  #   # ib_srpt

  #   # ib_ucm provides the obsolete /dev/infiniband/ucm0
  #   # ib_ucm

  #   # These modules are loaded by the system if any RDMA devices is installed
  #   # iSCSI over RDMA client support
  #   "ib_iser"

  #   # iSCSI over RDMA target support
  #   # ib_isert

  #   # User access to RDMA verbs (supports libibverbs)
  #   "ib_uverbs"

  #   # User access to RDMA connection management (supports librdmacm)
  #   "rdma_ucm"

  #   # RDS over RDMA support
  #   # rds_rdma

  #   # NFS over RDMA client support
  #   "xprtrdma"

  #   # NFS over RDMA server support
  #   "svcrdma"
  # ];
  environment.systemPackages = with pkgs; [
    opensm
    rdma-core
    mstflint
  ];
  systemd.services.rdma = {
    enable = false;
    wantedBy = ["network.target"];
    description = "Load RDMA modules";
    documentation = ["man:opensm"];
    conflicts = ["shutdown.target"];
    before = ["shutdown.target" "network-pre.target"];
    unitConfig = {
      ConditionCapability = ["CAP_SYS_MODULE"];
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
      ExecStart = [
        "${pkgs.systemd}/lib/systemd/systemd-modules-load ${pkgs.rdma-core}/etc/rdma/modules/infiniband.conf"
        "${pkgs.systemd}/lib/systemd/systemd-modules-load ${pkgs.rdma-core}/etc/rdma/modules/rdma.conf"
      ];
      TimeoutSec = "90s";
    };
  };
  systemd.services.opensm = {
    enable = true;
    wantedBy = ["network.target"];
    #after = ["rdma.service"];
    #requires = ["rdma.service"];
    description = "Starts the OpenSM InfiniBand fabric Subnet Manager";
    documentation = ["man:opensm"];
    before = ["network.target" "remote-fs-pre.target"];
    unitConfig = {
      DefaultDependencies = "no";
    };
    serviceConfig = {
      Type = "forking";
      ExecStart = ''${opensm-launch}/bin/opensm.launch'';
    };
  };
  # environment.etc = {
  #   "modprobe.d/mlx4_core.conf".text = ''
  #     options mlx4_core port_type_array=1,2 num_vfs=8 probe_vf=8 msi_x=1 enable_4k_uar=1 enable_qos=1 log_num_mac=7 log_num_mgm_entry_size=-1 log_mtts_per_seg=4
  #   '';
  # };
}
