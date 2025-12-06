{
  config,
  pkgs,
  username,
  ...
}: {
  # mount a smb/cifs share
  services.rpcbind.enable = true; # needed for NFS

  systemd.mounts = [
    {
      type = "ext4";
      what = "/dev/disk/by-label/fluent";
      where = "/game";
      options = "x-systemd.automount,x-systemd.idle-timeout=1min,x-systemd.device-timeout=20,nofail";
      after = ["nvme-auto-game.service"];
      requires = ["nvme-auto-game.service"];
      wantedBy = ["multi-user.target"];
      unitConfig.DefaultDependencies = "no";
    }
  ];

  # systemd.services.ntfsfix = {
  #   enable = false;
  #   bindsTo = ["dev-disk-by\\x2duuid-10DAC033DAC0173E.device"];
  #   after = ["dev-disk-by\\x2duuid-10DAC033DAC0173E.device"];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = ["${pkgs.ntfs3g}/bin/ntfsfix -d /dev/disk/by-uuid/10DAC033DAC0173E"];
  #   };
  # };

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
      name = "game";
      address = "192.168.29.1";
      target = "nqn.2016-06.io.spdk:fluent";
      type = "rdma";
    }
  ];

  fileSystems."/fluent" = {
    device = "192.168.29.1:/share";
    fsType = "nfs";
    options = ["x-systemd.automount" "x-systemd.idle-timeout=1min" "nofail" "nfsvers=4.2" "proto=rdma" "port=20049" "async"];
  };
}
