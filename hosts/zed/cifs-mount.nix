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
      what = "/dev/disk/by-label/fluent";
      where = "/fluent";
      options = "x-systemd.device-timeout=20,nofail";
      after = ["nvme-auto-fluent.service"];
      requires = ["nvme-auto-fluent.service"];
      wantedBy = ["multi-user.target"];
      unitConfig.DefaultDependencies = "no";
    }
  ];

  systemd.services.ntfsfix = {
    enable = false;
    bindsTo = ["dev-disk-by\\x2duuid-10DAC033DAC0173E.device"];
    after = ["dev-disk-by\\x2duuid-10DAC033DAC0173E.device"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = ["${pkgs.ntfs3g}/bin/ntfsfix -d /dev/disk/by-uuid/10DAC033DAC0173E"];
    };
  };

  # systemd.automounts = [
  #   {
  #     wantedBy = ["multi-user.target"];
  #     automountConfig = {
  #       TimeoutIdleSec = "600";
  #     };
  #     after = ["nvme-auto-fluent.service"];
  #     where = "/fluent";
  #   }
  # ];

  services.nvme-auto = [
    {
      name = "fluent";
      address = "192.168.29.1";
      target = "nqn.2016-06.io.spdk:fluent";
      type = "rdma";
    }
  ];

  # fileSystems."/nfs" = {
  #   device = "192.168.29.1:/share";
  #   fsType = "nfs";
  #   options = ["x-systemd.automount" "noauto" "nfsvers=4.2" "proto=rdma" "port=20049"];
  # };
}
