{
  config,
  pkgs,
  lib,
  ...
}: let
  username = "wf";
in {
  imports = [
    # Include the results of the hardware scan.
    ./system.nix

    ./sever

    ../../secrets/agenix.nix
  ];

  # enable flakes globally
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # do garbage collection weekly to keep disk usage low
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 1d";
  };

  boot.binfmt.emulatedSystems = builtins.filter (p: p != pkgs.stdenv.hostPlatform.system) ["aarch64-linux" "x86_64-linux"];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = ["tcp_bbr"];
  boot.kernel.sysctl = {
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  # test user doesn't have a password
  services.openssh.settings.PasswordAuthentication = false;
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
  ];

  users.users."${username}" = {
    isNormalUser = true;
    home = "/home/${username}";
    extraGroups = ["wheel"]; # Enable ‘sudo’ for the user.
    # description = "Azure NixOS Test User";
    openssh.authorizedKeys.keys = [
      # azure
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ/IRGPdWpQ9iT1bdm51hWhTkv3hwNjEjR8SArP6ni/U"

      # homelab
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDO/MVQ2jBtTwjqFsr1HpZeAcp9LE14g7FZEH9xaI5jq+9SFoSJF3GcFi15T7HxRtQ9l/CEaTVVbEbvIEynORVIfo9qR6vJYS7OyWt//rorIVCWyYsfEVLkX1vbq/wIe5aaWXHt8ePZy3up2bAewFok8z4wRYq2vhP5yI9/WckqKFWdZQ5+7CXJEdpec3ye5+G3Q+VgkHb4ZzjjgPbeoWp9tpFh5LVw+Trw3gyI9TxsXnWZUKD/v/mirNodAFN6O0owkqbo1fvAAfLM7U02mHIxJ1jc0DrCGUm4hVR9oRGcmPlsjT9D0oILkHt0LDPhmnWw4o0iyZZPtp3AcacJvb33wRy2VOUrkGjn2e8JwLSB68tXrrmk0ashFie3kFkumpf5lMnqSB5RLG1t+C9yP5S7ge7Usndphwe+vUgeNGNKfPmFdV+jEl2gi8GuIX99UGIHZCcwaGCqnELH00rSTPbGmBoGNaAZU6FHDloMrHqwhuR85kpQow7aBMu7APou7B8="
    ];
  };

  users.defaultUserShell = pkgs.zsh;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    vteIntegration = true;
    histSize = 1048576;
    syntaxHighlighting.enable = true;

    ohMyZsh = {
      enable = true;
      plugins = [
        "docker"
        "git"
        "golang"
        "systemd"
        "git-auto-fetch"
        "history-substring-search"
      ];
      theme = "candy";
    };
  };

  networking.firewall.enable = lib.mkForce false;

  # nix.settings.trusted-users = [ username ];
  nix.settings.trusted-users = ["@wheel"];
}
