{
  lib,
  pkgs,
  username,
  config,
  mysecrets,
  ...
}: {
  services.ddns-go = {
    enable = false;
  };
}
