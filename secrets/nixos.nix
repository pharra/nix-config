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
  age.identityPaths = [
    "/home/${username}/.ssh/id_ed25519" # Linux
  ];

  sops = {
    defaultSopsFile = ./default.yaml;

    age = {
      sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      generateKey = true;
    };

    secrets = lib.mkIf config.services.mihomo.enable (lib.genAttrs [
      "mihomo/providers/yiyuan"
      "mihomo/providers/llg"
      "mihomo/providers/l666"
    ] (name: {restartUnits = ["mihomo.service"];}));
  };
}
