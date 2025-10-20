{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.services.netns;
in {
  options.services.netns = {
    enable = mkEnableOption "Create Network Namespace";

    names = lib.mkOption {
      type = with types;
        listOf str;
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services = listToAttrs (map (
        name: {
          name = "netns@${name}";
          value = {
            description = "Network namespace instance ${name}";
            wantedBy = ["multi-user.target" "network-online.target"];
            path = with pkgs; [
              iproute2
              util-linux
            ];
            serviceConfig = {
              PrivateNetwork = true;
              PrivateMounts = "no";
              Type = "oneshot";
              RemainAfterExit = "yes";
              ExecStart = pkgs.writeShellScript "create-netns-${name}" ''
                echo "Creating network namespace ${name}"
                ip netns add ${name}
                #umount /var/run/netns/${name}
                #mount --bind /proc/self/ns/net /var/run/netns/${name}
                ip netns exec ${name} ip link set lo up

                mkdir -p /etc/netns/${name}
                echo "nameserver 114.114.114.114" > /etc/netns/${name}/resolv.conf
              '';
              ExecStop = pkgs.writeShellScript "create-netns-${name}" ''
                echo "Deleteing network namespace ${name}"
                ip netns delete ${name}
                rm -rf /etc/netns/${name}
              '';
            };
          };
        }
      )
      cfg.names);
  };
}
