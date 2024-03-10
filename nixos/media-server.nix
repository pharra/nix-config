{
  pkgs,
  lib,
  config,
  utils,
  inputs,
  ...
} @ args: {
  services.sonarr = {
    enable = true;
    user = "sftp";
    group = "sftp";
  };

  services.radarr = {
    enable = true;
    user = "sftp";
    group = "sftp";
  };

  services.prowlarr = {
    enable = true;
  };

  services.jellyfin = {
    enable = true;
    user = "sftp";
    group = "sftp";
  };

  services.jellyseerr = {
    enable = true;
  };
}
