{
  config,
  pkgs,
  username,
  lib,
  ...
}: {
  nix =
    lib.mkIf (
      config.networking.hostName
      == "zed"
      || config.networking.hostName == "dot"
      || config.networking.hostName == "homelab"
    ) {
      extraOptions = ''
        experimental-features = nix-command flakes
        !include ${config.sops.secrets.nixAccessTokens.path}
      '';
    };

  sops.secrets.nixAccessTokens = {
    mode = "0440";
    group = config.users.groups.keys.name;
    sopsFile = ./github.yaml;
  };
}
