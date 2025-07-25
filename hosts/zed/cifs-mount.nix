{
  config,
  pkgs,
  username,
  ...
}: {
  # mount a smb/cifs share
  services.rpcbind.enable = true; # needed for NFS

  # systemd.mounts = [
  #   {
  #     type = "nfs";
  #     mountConfig = {
  #       Options = "vers=4,proto=rdma,port=20049";
  #     };
  #     what = "192.168.29.1:/share";
  #     where = "/nfs";
  #   }
  # ];

  # systemd.automounts = [
  #   {
  #     wantedBy = ["multi-user.target"];
  #     automountConfig = {
  #       TimeoutIdleSec = "600";
  #     };
  #     where = "/nfs";
  #   }
  # ];

  systemd.mounts = [
    {
      type = "ext4";
      what = "/dev/disk/by-label/zed";
      where = "/zed";
    }
    {
      type = "exfat";
      what = "/dev/disk/by-uuid/38C7-538C";
      where = "/common";
      options = "uid=1000,gid=100";
    }
  ];

  systemd.automounts = [
    {
      wantedBy = ["multi-user.target"];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      requires = ["nvme-auto-zed.service"];
      where = "/zed";
    }
    {
      wantedBy = ["multi-user.target"];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      requires = ["nvme-auto-common.service"];
      where = "/common";
    }
  ];

  services.nvme-auto = [
    {
      name = "zed";
      address = "192.168.29.1";
      target = "nqn.2016-06.io.spdk:zed";
      type = "rdma";
    }
    {
      name = "common";
      address = "192.168.29.1";
      target = "nqn.2016-06.io.spdk:common";
      type = "rdma";
    }
  ];

  # fileSystems."/nfs" = {
  #   device = "192.168.29.1:/share";
  #   fsType = "nfs";
  #   options = ["x-systemd.automount" "noauto" "nfsvers=4.2" "proto=rdma" "port=20049"];
  # };
}
