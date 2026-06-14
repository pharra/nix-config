{
  config,
  pkgs,
  agenix,
  mysecrets,
  username,
  lib,
  ...
}: {
  imports = [
    ./agenix.nix
    ./github.nix
  ];

  sops = {
    defaultSopsFile = ./default.yaml;

    age = {
      sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      generateKey = true;
    };
  };
}
