{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./caddy
    ./emby
    ./mybili
    ./substore
    ./reader
    ./clouddrive2
    ./immich
    ./magnet
    ./xray
  ];
}
