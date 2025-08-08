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
    }
    {
      type = "ntfs3";
      what = "/dev/disk/by-uuid/10DAC033DAC0173E";
      where = "/common";
      # options = "uid=1000,gid=100";
    }
    {
      type = "ext4";
      what = "/dev/disk/by-label/steam_compact";
      where = "/common/SteamLibrary/steamapps/compatdata";
    }
  ];

  systemd.services.ntfsfix = {
    enable = true;
    wantedBy = ["multi-user.target"];
    after = ["nvme-auto-common.service"];
    unitConfig = {
      DefaultDependencies = "no";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = ["${pkgs.ntfs3g}/bin/ntfsfix -d /dev/disk/by-uuid/10DAC033DAC0173E"];
    };
  };

  systemd.automounts = [
    {
      wantedBy = ["multi-user.target"];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      before = ["libvirtd.service"];
      where = "/fluent";
    }
    {
      wantedBy = ["multi-user.target"];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      after = ["ntfsfix.service"];
      where = "/common";
    }
    {
      wantedBy = ["multi-user.target"];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      after = ["ntfsfix.service"];
      where = "/common/SteamLibrary/steamapps/compatdata";
    }
  ];

  services.nvme-auto = [
    {
      name = "fluent";
      address = "192.168.29.1";
      target = "nqn.2016-06.io.spdk:fluent";
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
