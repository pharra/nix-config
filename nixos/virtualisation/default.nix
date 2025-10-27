{
  pkgs,
  lib,
  config,
  utils,
  inputs,
  username,
  ...
} @ args: {
  environment.systemPackages = with pkgs; [
    docker-compose
    podman-compose
    distrobox
  ];

  virtualisation.docker = {
    enable = true;
    daemon.settings.features.cdi = true;
    daemon.settings.live-restore = false;
    daemon.settings.dns = ["114.114.114.114"]; # if not set, docker compose will fail to resolve hostnames
  };
  virtualisation.containers.enable = true;
  virtualisation.oci-containers.backend = "podman";
  virtualisation = {
    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = false;
      autoPrune.enable = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
