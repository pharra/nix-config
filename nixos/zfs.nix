{
  lib,
  pkgs,
  username,
  config,
  ...
}: {
  environment.systemPackages = [
    #pkgs.zfs
    #pkgs.sysbench
    pkgs.fio
    #pkgs.smartmontools
  ];
}
