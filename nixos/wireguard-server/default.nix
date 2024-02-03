{
  pkgs,
  lib,
  config,
  utils,
  inputs,
  mysecrets,
  ...
} @ args: {
  age.secrets."wireguard_homelab_private_key" = {
    file = "${mysecrets}/wireguard_homelab_private_key.age";
    mode = "644";
  };

  systemd.network = {
    enable = true;
    netdevs = {
      "50-wg0" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
          MTUBytes = "1300";
        };
        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.wireguard_homelab_private_key.path;
          ListenPort = 51820;
        };
        wireguardPeers = [
          {
            wireguardPeerConfig = {
              PublicKey = "DyVEfec2pfgzu+H3vqnRARpY6NhOQ1LBKmpZEJ1rzWk=";
              AllowedIPs = ["10.100.0.2"];
            };
          }
        ];
      };
    };
    networks.wg0 = {
      matchConfig.Name = "wg0";
      address = ["10.100.0.1/24"];
      networkConfig = {
        IPMasquerade = "ipv4";
        IPForward = true;
      };
    };
  };
}
