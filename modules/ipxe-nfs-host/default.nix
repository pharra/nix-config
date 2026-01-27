# Host module: Serve guest NixOS system via iPXE and NFS
# This module is used on the host machine that provides boot services
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.ipxe-nfs-host;

  # Build each guest's iPXE script and kernel params
  guestConfigs = mapAttrs (
    name: guestCfg: let
      guestSystem = guestCfg.system;
      kernelParams = [
        "init=${guestSystem.config.system.build.toplevel}/init"
        "ip=dhcp"
      ];
      
      baseUrl = "http://\${http-server}:8080/ipxe";
      kernelUrl = "${baseUrl}/${name}/bzImage";
      initrdUrl = "${baseUrl}/${name}/initrd";
    in {
      inherit guestSystem kernelParams;
      inherit kernelUrl initrdUrl;
      nfsExportPath = "${guestSystem.config.system.build.toplevel}/nix/store";
      kernelPath = guestSystem.config.system.build.kernel + "/bzImage";
      initrdPath = guestSystem.config.system.build.initialRamdisk + "/initrd";
    }
  ) cfg.guests;
in {
  options = {
    services.ipxe-nfs-host = {
      enable = mkEnableOption "iPXE and NFS host for guest systems";

      guests = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            system = mkOption {
              type = types.unspecified;
              description = "The guest NixOS system configuration (built system).";
            };

            macAddress = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Optional MAC address for auto-boot.";
            };
          };
        });
        default = {};
        description = "Guest systems to serve via iPXE and NFS.";
      };
    };
  };

  config = mkIf cfg.enable {
    # Setup NFS server to export guest stores with RDMA support
    services.nfs.server = {
      enable = true;
      extraNfsdConfig = ''
        rdma=y
        rdma-port=20049
      '';
      exports = concatStringsSep "\n" (
        mapAttrsToList (
          name: guestInfo:
            "${guestInfo.nfsExportPath} *(ro,sync,no_subtree_check,no_root_squash)"
        )
        guestConfigs
      );
    };

    # Setup static web server for iPXE assets
    services.static-web-server = {
      enable = true;
      listen = "[::]:8080";
      root = "/etc/ipxe";
    };

    environment.systemPackages = with pkgs; [
      ipxe
      nfs-utils
    ];

    # Generate iPXE scripts and serve guest kernels/initrds
    environment.etc =
      # iPXE boot files
      {
        "ipxe/ipxe.efi".source = pkgs.ipxe + "/ipxe.efi";
        "ipxe/undionly.kpxe".source = pkgs.ipxe + "/undionly.kpxe";

        "ipxe/boot.ipxe".text = ''
          #!ipxe
          dhcp
          chain --autofree boot.ipxe.cfg || chain --replace --autofree menu.ipxe ||
        '';

        "ipxe/boot.ipxe.cfg".text = ''
          #!ipxe
          set http-server ''${gateway}
          set nfs-server ''${gateway}
          set menu-url menu.ipxe
        '';

        "ipxe/menu.ipxe".text = let
          guestMenuItems = concatStringsSep "\n" (
            mapAttrsToList (name: _: "item ${name}      Boot ${name}") cfg.guests
          );

          macChecks = concatStringsSep "\n" (
            filter (x: x != "") (
              mapAttrsToList (
                name: guestCfg:
                  optionalString (guestCfg.macAddress != null)
                    "iseq \${net0/mac} ${guestCfg.macAddress} && goto ${name} ||"
              )
              cfg.guests
            )
          );

          guestBootSections = concatStringsSep "\n\n" (
            mapAttrsToList (
              name: guestInfo: ''
                :${name}
                kernel ${guestInfo.kernelUrl} ${concatStringsSep " " guestInfo.kernelParams}
                initrd ${guestInfo.initrdUrl}
                boot || goto failed
              ''
            )
            guestConfigs
          );
        in ''
          #!ipxe
          ${macChecks}
          menu iPXE NFS Boot
          ${guestMenuItems}
          item shell Shell
          choose target && goto ''${target}

          :failed
          :shell
          shell
          goto menu

          ${guestBootSections}
        '';
      }
      // (
        # Generate kernel and initrd files for each guest
        listToAttrs (
          flatten (
            mapAttrsToList (
              name: guestInfo: [
                {
                  name = "ipxe/${name}/bzImage";
                  value.source = guestInfo.kernelPath;
                }
                {
                  name = "ipxe/${name}/initrd";
                  value.source = guestInfo.initrdPath;
                }
              ]
            )
            guestConfigs
          )
        )
      );

    # Open firewall for NFS and HTTP
    networking.firewall.allowedTCPPorts = [8080 2049 20049 111];
    networking.firewall.allowedUDPPorts = [2049 111];

    # Load kernel modules for NFS over RDMA
    boot.kernelModules = ["svcrdma" "xprtrdma"];
  };
}
