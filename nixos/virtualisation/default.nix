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
    podman-compose
    distrobox
    # swtpm
  ];

  virtualisation.docker = {
    enable = true;
    daemon.settings.features.cdi = true;
    daemon.settings.ipv6 = true;
    daemon.settings.fixed-cidr-v6 = "fd00::/80";
    rootless = {
      enable = false;
      daemon.settings.features.cdi = true;
      daemon.settings.ipv6 = true;
      daemon.settings.fixed-cidr-v6 = "fd00::/80";
      setSocketVariable = true;
    };
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
