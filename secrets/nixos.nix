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
    agenix.nixosModules.default
    ./github.nix
  ];

  environment.systemPackages = [
    agenix.packages."${pkgs.system}".default
  ];

  # # if you changed this key, you need to regenerate all encrypt files from the decrypt contents!
  age.identityPaths =
    if (config.environment.persistence != {})
    then [
      "/nix/persistent/home/${username}/.ssh/id_ed25519"
    ]
    else ["/home/${username}/.ssh/id_ed25519"];

  sops = {
    defaultSopsFile = ./default.yaml;

    age = {
      sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      generateKey = true;
    };
  };
}
