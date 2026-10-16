{
  config,
  pkgs,
  agenix,
  mysecrets,
  username,
  lib,
  ...
}: {
  # 注意：这里不再 imports agenix.nixosModules.default ——
  # lib/default.nix 的 common-nixos-modules 已经对所有配置加过一次，重复 import 只是噪音。

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
