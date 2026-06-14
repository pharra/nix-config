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
}
