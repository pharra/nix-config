{
  pkgs,
  lib,
  config,
  utils,
  inputs,
  ...
} @ args: {
  environment.systemPackages = with pkgs; [
    cloud-hypervisor
    docker-compose
    distrobox
    # swtpm
  ];

  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
      # daemon.settings = {
      #   "userns-remap" = "${username}";
      # };
    };
    daemon.settings.features.cdi = true;
    rootless.daemon.settings.features.cdi = true;
  };
  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = false;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
