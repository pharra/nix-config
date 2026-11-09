# 实现：按选项渲染 dnsmasq 配置并起服务。
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.pharra.dhcp-server;
  inherit (import ./format.nix {inherit lib pkgs;}) settingsFormat;
in {
  config = mkIf cfg.enable {
    # Open DHCP ports on participating LAN interfaces.
    networking.firewall.interfaces =
      mapAttrs' (_: network: {
        name = network.interface;
        value = {
          # allowedTCPPorts = [80];
          # allowedUDPPorts = [53 67 69 547 5353];
          allowedUDPPortRanges = [
            {
              from = 0;
              to = 65535;
            }
          ];
          allowedTCPPortRanges = [
            {
              from = 0;
              to = 65535;
            }
          ];
        };
      })
      cfg.networks;

    networking.firewall.allowPing = true;

    boot.kernel.sysctl."net.ipv4.ip_forward" = "1";
    boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = "1";

    # Dnsmasq is used as the DHCP server.
    users.users.dnsmasq = {
      isSystemUser = true;
      group = "dnsmasq";
      description = "Dnsmasq daemon user";
    };
    users.groups.dnsmasq = {};
    systemd.services = listToAttrs (forEach (filter (n: n.enableDnsmasq != false) (attrValues cfg.networks)) (
      network: let
        iface = network.interface;
        stateDir = "/var/lib/dnsmasq-${iface}";
        # Format static host entries for dnsmasq dhcp-host option
        # Format: dhcp-host=MAC,IP[,hostname]
        staticHostEntries =
          map (
            host:
              if host.hostname != null
              then "${host.mac},${host.ip},${host.hostname}"
              else "${host.mac},${host.ip}"
          )
          network.staticHosts;
        dnsmasqConf = settingsFormat.generate "dnsmasq-${iface}.conf" ({
            interface = [iface];
            dhcp-range = lib.concatLists [
              ["interface:${iface},${network.ipv4.pool},${network.leaseTime}"]
              (lib.optional network.ipv6.enable "${network.ipv6.pool},constructor:${iface},ra-stateless,${network.leaseTime}")
            ];
            # Add static host assignments
            dhcp-host = staticHostEntries;
            listen-address = lib.concatLists [
              ["${network.ipv4.address}"]
              (lib.optional network.ipv6.enable "${network.ipv6.address}")
            ];
            dhcp-option =
              if network.emitRoute == false
              then
                lib.concatLists [
                  ["interface:${iface},3"]
                  ["interface:${iface},6"]
                  ["interface:${iface},option6:3"]
                  ["interface:${iface},option6:dns-server"]
                ]
              else
                lib.concatLists [
                  ["interface:${iface},6,${network.ipv4.address}"]
                  (lib.optional network.ipv6.enable "interface:${iface},option6:dns-server,[${network.ipv6.address}]")
                ];
            except-interface = ["lo"];
            bind-interfaces = true;
            log-dhcp = true;
            dhcp-leasefile = "${stateDir}/dnsmasq-${iface}.leases";
            # local = "/${network.domain}/";
            # domain = network.domain;
            expand-hosts = true;
            no-hosts = true;
            server = "114.114.114.114";
            # host-record = [hostrecord];
          }
          // lib.optionalAttrs network.boot.tftp.enable {
            enable-tftp = true;
            tftp-root = network.boot.tftp.root;
          }
          // lib.optionalAttrs (network.boot.dhcpMatch != []) {
            dhcp-match = network.boot.dhcpMatch;
          }
          // lib.optionalAttrs (network.boot.dhcpBoot != []) {
            dhcp-boot = network.boot.dhcpBoot;
          });
      in {
        name = "dnsmasq-${iface}";
        value = {
          description = "Dnsmasq Daemon for ${iface}";
          after = [
            "network.target"
            "systemd-resolved.service"
          ];
          wantedBy = ["multi-user.target"];
          path = [pkgs.dnsmasq];
          preStart = ''
            mkdir -m 755 -p ${stateDir}
            touch ${stateDir}/dnsmasq-${iface}.leases
            chown -R dnsmasq ${stateDir}
            ${pkgs.dnsmasq}/bin/dnsmasq --test -C ${dnsmasqConf}
          '';
          serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.dnsmasq}/bin/dnsmasq -k --user=dnsmasq -C ${dnsmasqConf} -x /run/dnsmasq-${iface}.pid";
            PrivateTmp = true;
            ProtectSystem = true;
            ProtectHome = true;
            Restart = "on-failure";
          };
          restartTriggers = [config.environment.etc.hosts.source];
        };
      }
    ));

    systemd.network.networks = listToAttrs (forEach (attrValues cfg.networks) (network: {
      name = "50-${network.interface}";
      value = {
        matchConfig.Name = "${network.interface}";
        bridgeConfig = {};
        networkConfig = {
          Address = lib.concatLists [
            ["${network.ipv4.address}/${network.ipv4.netmask}"]
            (lib.optional network.ipv6.enable "${network.ipv6.address}/${network.ipv6.netmask}")
          ];
          DNS =
            if network.enableDnsmasq
            then
              lib.concatLists [
                ["${network.ipv4.address}"]
                (lib.optional network.ipv6.enable "${network.ipv6.address}")
              ]
            else ["114.114.114.114"];
          IPMasquerade = network.masquerade;
          ConfigureWithoutCarrier = true;
          IPv6AcceptRA = false;
          IPv6PrivacyExtensions = "no";
          # Domains = ["${network.domain}"];
        };
        linkConfig = {
          # or "routable" with IP addresses configured
          ActivationPolicy = "always-up";
          RequiredForOnline = "no";
          # MTUBytes = "9000";
        };
      };
    }));
  };
}
