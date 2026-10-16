# 网络：接口命名、桥、DHCP 服务、docker netns、代理（mihomo）。
# 接口的 MAC→名字映射与网段都定义在本文件顶部，方便对照硬件。
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  interface = {
    eth-to-bridge = "eno2";
    eth = "mlx5_0";
    intern = "br1";
  };
  interfaces = [
    {
      mac = "50:65:f3:8a:c7:71";
      name = "mlx4_0";
    }
    {
      mac = "50:65:f3:8a:c7:72";
      name = "mlx4_1";
    }
    {
      mac = "f4:6b:8c:13:cf:e6";
      name = "mlx5_0";
    }
    {
      mac = "f4:6b:8c:13:cf:e7";
      name = "mlx5_1";
    }
  ];
in {
  services.mihomo.enable = true;

  services.mihomo.config.tun = lib.mkIf config.services.mihomo.enable {
    exclude-interface = [interface.eth interface.intern "docker"];
  };

  services.pharra.net-name = {
    enable = true;
    inherit interfaces;
  };

  services.pharra.openwrt.enable = false;

  services.pharra.docker-netns =
    if config.services.pharra.openwrt.enable
    then {
      enable = config.virtualisation.docker.enable;
      autoConfigureBridge = false;
      dockerBridge = "br2";
      dockerGateway = "192.168.31.254";
      dockerHostIP = "192.168.31.2";
    }
    else {
      enable = config.virtualisation.docker.enable;
      autoConfigureBridge = true;
      dockerGateway = "192.168.31.254";
      dockerHostIP = "192.168.31.2";
    };

  services.pharra.dhcp-server = {
    enable = true;
    networks = {
      eth = {
        name = "eth";
        interface = interface.eth;
        domain = "mlx";
        staticHosts = [
          {
            mac = "9c:52:f8:8e:dd:d8";
            ip = "192.168.29.2";
            hostname = "zed";
          }
        ];
        masquerade = "no";
        emitRoute = false;
        ipv4 = {
          address = "192.168.29.1";
          netmask = "24";
          pool = "192.168.29.50,192.168.29.150";
        };
        ipv6 = {
          enable = false; # disable IPv6 for this network
          address = "fdd4:c514:7378:0::1";
          netmask = "64";
          pool = "::";
        };
      };

      intern = {
        name = "intern";
        interface = interface.intern;
        domain = "intern";
        # staticHosts = [
        #   {
        #     mac = "58:47:ca:79:85:1c";
        #     ip = "192.168.28.2";
        #     hostname = "zed";
        #   }
        # ];
        masquerade = "no";
        emitRoute = false;
        ipv4 = {
          address = "192.168.28.1";
          netmask = "24";
          pool = "192.168.28.50,192.168.28.150";
        };
        ipv6 = {
          enable = false; # disable IPv6 for this network
          address = "fd00:0:28::1";
          pool = "::";
          netmask = "64";
        };
      };
    };
  };

  services.pharra.network-bridge = {
    enable = true;
    bridges = {
      br0 = {
        name = "br0";
        ports = ["eno1" "eno2"];
        dhcp = true;
        ipv6AcceptRA = true;
        domains = ["lan"];
      };
      br1 = {
        name = "br1";
        ports = [];
        configureNetwork = false;
      };
    };
  };

  networking = {
    hostName = "homelab";

    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    networkmanager.unmanaged = ["interface-name:*,except:interface-name:wl*"];
  };
}
