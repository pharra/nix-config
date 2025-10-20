{
  pkgs,
  lib,
  config,
  ...
}: let
  #dockerGateway = "172.17.254.1";
  #dockerHostIP = "172.17.254.2/24";
  dockerGateway = "192.168.31.254";
  dockerHostIP = "192.168.31.2/24";
  netns = "docker";
  hostVeth = "veth-${netns}-ns";
  dockerNsVeth = "veth-${netns}-br";
  # dockerBridge = "docker-br";
  dockerBridge = "br2";
in {
  virtualisation.docker.daemon.settings = {
    live-restore = false;
    dns = ["114.114.114.114"];
  };
  systemd.services.docker = {
    bindsTo = ["${netns}-netns.service"];
    after = ["${netns}-netns.service"];
    serviceConfig.NetworkNamespacePath = "/var/run/netns/${netns}";
  };

  services.netns = {
    enable = true;
    names = [netns];
  };

  # systemd.network = {
  #   enable = true;
  #   wait-online.anyInterface = true;
  #   netdevs = {
  #     # Create the bridge interface
  #     "20-${dockerBridge}" = {
  #       netdevConfig = {
  #         Kind = "bridge";
  #         Name = "${dockerBridge}";
  #       };
  #     };
  #   };
  # };

  # services.dhcpServer = {
  #   networks = {
  #     "${dockerBridge}" = {
  #       name = "${dockerBridge}";
  #       interface = "${dockerBridge}";
  #       domain = "docker";
  #       enableDnsmasq = false;
  #       masquerade = "yes";
  #       ipv4 = {
  #         address = "${dockerGateway}";
  #         netmask = "24";
  #         # pool = "172.17.254.50,172.17.254.150";
  #       };
  #       ipv6 = {
  #         enable = false; # disable IPv6 for this network
  #       };
  #     };
  #   };
  # };

  systemd.services."${netns}-netns" = {
    bindsTo = ["netns@${netns}.service"];
    after = ["netns@${netns}.service"];
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
}
