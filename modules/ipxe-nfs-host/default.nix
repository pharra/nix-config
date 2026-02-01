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
  guestConfigs =
    mapAttrs (
      name: guestCfg: let
        guestSystem = guestCfg.system;
        kernelParams = [
          "init=${guestSystem.config.system.build.toplevel}/init"
          "${toString guestSystem.config.boot.kernelParams}"
        ];
      in {
        inherit guestSystem kernelParams;
        kernelUrl = "${name}/bzImage";
        initrdUrl = "${name}/initrd";
        kernelPath = guestSystem.config.system.build.kernel + "/bzImage";
        initrdPath = guestSystem.config.system.build.initialRamdisk + "/initrd";
      }
    )
    cfg.guests;
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
          };
        });
        default = {};
        description = "Guest systems to serve via iPXE and NFS.";
      };
    };
  };

  config = mkIf cfg.enable {
    services.nfs = {
      server = {
        enable = true;
        lockdPort = 4001;
        mountdPort = 4002;
        statdPort = 4000;
        exports = "/nix/store *(ro,sync,no_subtree_check,no_root_squash,nohide,insecure)";
      };
      settings = {
        nfsd.tcp = true;
        nfsd.rdma = true;
        nfsd.vers2 = false;
        nfsd.vers3 = false;
        nfsd.vers4 = true;
      };
    };

    # Setup static web server for iPXE assets
    services.static-web-server = {
      enable = true;
      listen = "[::]:8080";
      root = "/etc/ipxe";
      configuration = {
        general = {
          directory-listing = true;
          log-level = "error";
        };
      };
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
          chain --autofree boot.ipxe.cfg ||
          chain --replace --autofree ''${menu-url} ||
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

          guestBootSections = concatStringsSep "\n\n" (
            mapAttrsToList (
              name: guestInfo: ''
                :${name}
                kernel http://''${http-server}:8080/${guestInfo.kernelUrl} ${concatStringsSep " " guestInfo.kernelParams}
                initrd http://''${http-server}:8080/${guestInfo.initrdUrl}
                boot || goto failed
              ''
            )
            guestConfigs
          );
        in ''
          #!ipxe

          # Some menu defaults
          set menu-timeout 50000
          set submenu-timeout ''${menu-timeout}

          :start
          menu iPXE NFS Boot Menu
          item --gap --             ------------------------- Operating systems ------------------------------
          ${guestMenuItems}
          item --gap --             ------------------------- Advanced options -------------------------------
          item shell                Drop to iPXE shell
          item reboot               Reboot computer
          item
          item --key x exit         Exit iPXE and continue BIOS boot
          choose --default exit --timeout ''${menu-timeout} target && goto ''${target}

          :cancel
          echo You cancelled the menu, dropping you to a shell

          :failed
          :shell
          echo Type 'exit' to get back to the menu
          shell
          set menu-timeout 0
          set submenu-timeout 0
          goto start

          :reboot
          reboot

          :exit
          exit

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
    networking.firewall.allowedTCPPorts = [8080 2049 111 4000 4001 4002 20049];
    networking.firewall.allowedUDPPorts = [2049 111 4000 4001 4002];

    # Load kernel modules for NFS over RDMA
    boot.kernelModules = ["svcrdma" "xprtrdma"];
  };
}
