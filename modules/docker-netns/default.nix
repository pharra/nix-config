{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.services.docker-netns;
in {
  options.services.docker-netns = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    autoConfigureBridge = mkOption {
      type = types.bool;
      default = true;
    };

    dockerBridge = mkOption {
      default = "docker";
      type = types.str;
    };

    dockerGateway = mkOption {
      default = "172.17.254.1";
      type = types.str;
    };
    dockerHostIP = mkOption {
      default = "172.17.254.2/24";
      type = types.str;
    };
    netns = mkOption {
      default = "docker";
      type = types.str;
    };
  };

  config = mkIf cfg.enable (let
    netns = cfg.netns;
    hostVeth = "veth-${netns}-ns";
    dockerNsVeth = "veth-${netns}-br";
    dockerBridge = cfg.dockerBridge;
    dockerHostIP = cfg.dockerHostIP;
    dockerGateway = cfg.dockerGateway;
  in {
    services.netns = {
      enable = true;
      names = [netns];
    };

    environment.systemPackages = with pkgs; [
      iptables
    ];

    systemd.services.docker = {
      bindsTo = ["${netns}-netns.service"];
      after = ["${netns}-netns.service"];
      serviceConfig.NetworkNamespacePath = "/var/run/netns/${netns}";
    };

    systemd.network = mkIf cfg.autoConfigureBridge {
      enable = true;
      wait-online.anyInterface = true;
      netdevs = {
        # Create the bridge interface
        "20-${dockerBridge}" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "${dockerBridge}";
          };
        };
      };
    };

    services.dhcpServer = mkIf cfg.autoConfigureBridge {
      enable = true;
      networks = {
        "${dockerBridge}" = {
          name = "${dockerBridge}";
          interface = "${dockerBridge}";
          domain = "${netns}";
          enableDnsmasq = false;
          masquerade = "ipv4";
          ipv4 = {
            address = "${dockerGateway}";
            netmask = "24";
          };
          ipv6 = {
            enable = false;
          };
        };
      };
    };

    systemd.services."${netns}-netns" = {
      bindsTo = ["netns@${netns}.service"];
      after = ["netns@${netns}.service" "systemd-networkd.service"];
      serviceConfig.NetworkNamespacePath = "/var/run/netns/${netns}";
      path = with pkgs; [
        iproute2
        util-linux
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        ExecStart = pkgs.writeShellScript "start-${netns}-netns" ''
          # add veth pair connecting docker namespace to the bridge
          nsenter -t 1 -n -- ip link add ${hostVeth} type veth peer name ${dockerNsVeth}
          nsenter -t 1 -n -- ip link set ${hostVeth} netns ${netns}
          nsenter -t 1 -n -- ip link set ${dockerNsVeth} master ${dockerBridge}

          # set interfaces up
          ip link set ${hostVeth} up
          nsenter -t 1 -n -- ip link set ${dockerNsVeth} up

          ip addr add ${dockerHostIP} dev ${hostVeth}
          ip route add default via ${dockerGateway} dev ${hostVeth}
        '';
        ExecStop = pkgs.writeShellScript "stop-${netns}-netns" ''
          ip link set ${hostVeth} down
          ip link del ${hostVeth}
        '';
      };
    };
  });
}
