{
  lib,
  pkgs,
  config,
  libs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    dpdk
    spdk
  ];
}
