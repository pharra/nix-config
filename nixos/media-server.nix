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
    user = "sftp";
    group = "sftp";
  };

  services.radarr = {
    enable = false;
    user = "sftp";
    group = "sftp";
  };

  services.prowlarr = {
    enable = false;
  };

  services.jellyfin = {
    enable = false;
    user = "sftp";
    group = "sftp";
  };

  services.jellyseerr = {
    enable = false;
  };
}
