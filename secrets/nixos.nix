{
  config,
  pkgs,
  agenix,
  mysecrets,
  username,
  ...
}: {
  imports = [
    agenix.nixosModules.default
  ];

  environment.systemPackages = [
    agenix.packages."${pkgs.system}".default
  ];

  # # if you changed this key, you need to regenerate all encrypt files from the decrypt contents!
  age.identityPaths = [
    "/home/${username}/.ssh/id_ed25519" # Linux
  ];
}
