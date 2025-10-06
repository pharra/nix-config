{
  pkgs,
  lib,
  config,
  utils,
  inputs,
  ...
} @ args: {
  services.sonarr = {
    enable = false;
  };

  services.radarr = {
    enable = false;
  };

  services.prowlarr = {
    enable = false;
  };

  services.jellyfin = {
    enable = false;
  };

  services.jellyseerr = {
    enable = false;
  };
}
