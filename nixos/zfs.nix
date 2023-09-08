{
  lib,
  pkgs,
  username,
  config,
  ...
}: {
  environment.systemPackages = [
    pkgs.zfs
  ];
}
