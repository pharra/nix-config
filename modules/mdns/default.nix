{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.networking.networkmanager.enable {
    networking = {
      networkmanager.connectionConfig = {
        "connection.mdns" = 2;
      };
    };
  };
}
