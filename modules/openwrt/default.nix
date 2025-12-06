{
  pkgs,
  lib,
  config,
  utils,
  ...
} @ args:
with lib; let
  netns = "openwrt";
  openwrtImage = pkgs.fetchurl {
    url = "https://github.com/pharra/OpenWrt-K/releases/download/v2025.10.23-0(x86-64)-(v24.10.3)-x86_64/openwrt-x86-64-generic-squashfs-combined.img.gz";
    hash = "sha256-SNoWBlHvgCqbNaA6SR85puUj6TsrS2OFnV0tezr5p4s=";
  };

  Kwrt = import ./Kwrt.nix args;

  mac-generator = import ./mac-generator.nix {inherit lib;};

  cfg = config.services.openwrt;
in {
  options.services.openwrt = {
    enable = mkEnableOption "Enable Openwrt virtual machine";
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts."init_openwrt" = ''
      mkdir -p /var/lib/openwrt
      if [ ! -f /var/lib/openwrt/overlay.img ]; then
        echo "Creating overlay..."
        ${pkgs.qemu-utils}/bin/qemu-img create -f raw /var/lib/openwrt/overlay.img 1G
        ${pkgs.btrfs-progs}/bin/mkfs.btrfs -L extroot -f /var/lib/openwrt/overlay.img
      fi
      if [ ! -f /var/lib/openwrt/openwrt.qcow2 ]; then
        echo "Decompressing OpenWRT image..."
        ${pkgs.gzip}/bin/gzip -cdq ${openwrtImage} > /var/lib/openwrt/openwrt.img || true
        ${pkgs.qemu-utils}/bin/qemu-img convert -f raw /var/lib/openwrt/openwrt.img -O qcow2 /var/lib/openwrt/openwrt.qcow2
      fi
    '';

    virtualisation.libvirt.connections."qemu:///system" = {
      domains = [
        Kwrt
      ];
    };

    systemd.network = {
      links = {
        "10-bridge" = {
          matchConfig = {Type = "bridge";};
          linkConfig = {MACAddressPolicy = "none";};
        };
      };
      netdevs = {
        "20-br2" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "br2";
            MACAddress = mac-generator.unicast "${config.networking.hostName}-br2";
          };
        };
      };
      networks = {
        "40-br0" = {
          enable = false;
        };
        "50-br0" = {
          matchConfig.Name = "br0";
          bridgeConfig = {};
          networkConfig = {
            IPv6AcceptRA = false;
            ConfigureWithoutCarrier = true;
          };
          linkConfig = {
            # or "routable" with IP addresses configured
            ActivationPolicy = "always-up";
          };
        };
        "40-br2" = {
          matchConfig.Name = "br2";
          bridgeConfig = {};
          networkConfig = {
            # start a DHCP Client for IPv4 Addressing/Routing
            DHCP = "ipv4";
            # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
            IPv6AcceptRA = true;
            Domains = ["lan"];
            ConfigureWithoutCarrier = true;
          };
          dhcpV4Config = {
            UseDomains = true;
            UseRoutes = true;
          };
          ipv6AcceptRAConfig = {
            UseDNS = true;
            UseDomains = true;
          };
          linkConfig = {
            # or "routable" with IP addresses configured
            ActivationPolicy = "always-up";
            RequiredForOnline = "routable";
          };
        };
      };
    };
  };
}
