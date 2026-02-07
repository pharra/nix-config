# Host module: Serve guest systems via iPXE with NFS or iSCSI boot
# This module provides unified iPXE boot configuration for both NFS and iSCSI targets
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.ipxe-host;

  # Build each NFS guest's iPXE script and kernel params
  nfsGuestConfigs =
    mapAttrs (
      name: guestCfg: let
        guestSystem = guestCfg.system;
        kernelParams = [
          "init=${guestSystem.config.system.build.toplevel}/init"
          "${toString guestSystem.config.boot.kernelParams}"
        ];
      in {
        inherit guestSystem kernelParams;
        macs = guestCfg.macs;
        kernelUrl = "${name}/bzImage";
        initrdUrl = "${name}/initrd";
        kernelPath = guestSystem.config.system.build.kernel + "/bzImage";
        initrdPath = guestSystem.config.system.build.initialRamdisk + "/initrd";
      }
    )
    cfg.nfs.guests;
in {
  options = {
    services.ipxe-host = {
      enable = mkEnableOption "Unified iPXE host for NFS and iSCSI boot";

      nfs = {
        enable = mkEnableOption "NFS boot support";

        zfsPool = mkOption {
          type = types.str;
          default = "system";
          description = "ZFS pool name for storing guest data.";
        };

        guests = mkOption {
          type = types.attrsOf (types.submodule {
            options = {
              system = mkOption {
                type = types.unspecified;
                description = "The guest NixOS system configuration (built system).";
              };
              macs = mkOption {
                type = types.listOf types.str;
                default = [];
                description = "MAC addresses that should auto-boot this guest (e.g. 52:54:00:12:34:56).";
              };
            };
          });
          default = {};
          description = "Guest systems to serve via iPXE and NFS.";
        };
      };

      iscsi = {
        enable = mkEnableOption "iSCSI boot support";

        items = mkOption {
          type = types.listOf (types.submodule {
            options = {
              macs = mkOption {
                type = types.listOf types.str;
                default = [];
                description = "MAC addresses that should auto-boot this iSCSI target.";
              };

              name = mkOption {
                type = types.str;
                description = "Name of this iSCSI boot item.";
              };

              iscsi-target = mkOption {
                type = types.str;
                description = "iSCSI target NQN.";
              };
            };
          });
          default = [];
          description = "iSCSI boot items to expose via iPXE menu.";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Create ZFS datasets and bind mounts for each NFS guest
    system.activationScripts."ipxe-nfs-datasets" = mkIf (cfg.nfs.enable && cfg.nfs.guests != {}) (let
      guestNames = builtins.attrNames cfg.nfs.guests;
      zfsPool = cfg.nfs.zfsPool;
      createDatasetCmds = concatStringsSep "\n" (
        map (
          guestName: ''
            # Create main guest dataset
            if ! zfs list -H -o name "''${pool}/${guestName}" &>/dev/null; then
              echo "Creating ZFS dataset: ''${pool}/${guestName}"
              zfs create "''${pool}/${guestName}"
            fi

            # Create nix dataset
            if ! zfs list -H -o name "''${pool}/${guestName}/nix" &>/dev/null; then
              echo "Creating ZFS dataset: ''${pool}/${guestName}/nix"
              zfs create "''${pool}/${guestName}/nix"
            fi

            # Create nix/persistent dataset
            if ! zfs list -H -o name "''${pool}/${guestName}/nix/persistent" &>/dev/null; then
              echo "Creating ZFS dataset: ''${pool}/${guestName}/nix/persistent"
              zfs create "''${pool}/${guestName}/nix/persistent"
            fi
          ''
        )
        guestNames
      );
    in ''
      set -e
      pool="${zfsPool}"
      PATH=${pkgs.zfs}/bin:$PATH

      # Check if ZFS pool exists
      if ! zfs list "''${pool}" &>/dev/null; then
        echo "Warning: ZFS pool ''${pool} does not exist, skipping dataset creation"
        exit 0
      fi

      ${createDatasetCmds}

      # Create mountpoint directories
      ${concatStringsSep "\n" (
        map (
          guestName: ''
            mkdir -p /${zfsPool}/${guestName}/nix/store
          ''
        )
        guestNames
      )}
    '');

    # Setup bind mounts for /nix/store
    systemd.mounts =
      if cfg.nfs.enable && (cfg.nfs.guests != {})
      then
        map (
          guestName: {
            what = "/nix/store";
            where = "/${cfg.nfs.zfsPool}/${guestName}/nix/store";
            type = "none";
            options = "bind,ro";
            wantedBy = ["local-fs.target"];
          }
        )
        (builtins.attrNames cfg.nfs.guests)
      else [];

    services.nfs = mkIf (cfg.nfs.enable && cfg.nfs.guests != {}) {
      server = {
        enable = true;
        lockdPort = 4001;
        mountdPort = 4002;
        statdPort = 4000;
        exports = concatStringsSep "\n" (
          map (
            guestName: "/${cfg.nfs.zfsPool}/${guestName}/nix *(rw,sync,no_subtree_check,no_root_squash,nohide,insecure,crossmnt)"
          )
          (builtins.attrNames cfg.nfs.guests)
        );
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

    environment.systemPackages = with pkgs;
      [ipxe]
      ++ lib.optionals cfg.nfs.enable [nfs-utils zfs];

    # Generate iPXE scripts
    environment.etc = let
      # Generate NFS menu items
      nfsMenuItems = concatStringsSep "\n" (
        mapAttrsToList (name: _: "item nfs-${name}   Boot ${name} (NFS)") cfg.nfs.guests
      );

      # Generate NFS MAC autoboot checks
      nfsMacAutobootChecks = concatStringsSep "\n" (
        flatten (
          mapAttrsToList (
            name: guestInfo:
              map (
                mac: ''iseq ''${net0/mac} ${mac} && goto nfs-${name}''
              )
              guestInfo.macs
          )
          nfsGuestConfigs
        )
      );

      # Generate NFS boot sections
      nfsBootSections = concatStringsSep "\n\n" (
        mapAttrsToList (
          name: guestInfo: ''
            :nfs-${name}
            kernel http://''${http-server}:8080/${guestInfo.kernelUrl} ${concatStringsSep " " guestInfo.kernelParams}
            initrd http://''${http-server}:8080/${guestInfo.initrdUrl}
            boot || goto failed
          ''
        )
        nfsGuestConfigs
      );

      # Generate iSCSI menu items
      iscsiMenuItems = concatStringsSep "\n" (
        map (item: "item iscsi-${item.name}   Boot ${item.name} (iSCSI)") cfg.iscsi.items
      );

      # Generate iSCSI MAC autoboot checks
      iscsiMacAutobootChecks = concatStringsSep "\n" (
        flatten (
          map (
            item:
              map (
                mac: ''iseq ''${net0/mac} ${mac} && goto iscsi-${item.name}''
              )
              item.macs
          )
          cfg.iscsi.items
        )
      );

      # Generate iSCSI boot sections
      iscsiBootSections = concatStringsSep "\n\n" (
        map (
          item: ''
            :iscsi-${item.name}
            echo Booting ${item.name}...
            sanboot --drive 0x80 iscsi:''${iscsi-server}::::${item.iscsi-target} || goto failed
          ''
        )
        cfg.iscsi.items
      );

      # Combined menu items and boot sections
      allMenuItems =
        (lib.optionalString cfg.nfs.enable "item --gap --             ------------------------- NFS Boot Targets -----------------------------------\n${nfsMenuItems}")
        + (lib.optionalString (cfg.nfs.enable && cfg.iscsi.enable) "\n")
        + (lib.optionalString cfg.iscsi.enable "item --gap --             ------------------------- iSCSI Boot Targets ---------------------------------\n${iscsiMenuItems}");

      allAutobootChecks =
        (lib.optionalString cfg.nfs.enable nfsMacAutobootChecks)
        + (lib.optionalString (cfg.nfs.enable && cfg.iscsi.enable) "\n")
        + (lib.optionalString cfg.iscsi.enable iscsiMacAutobootChecks);

      allBootSections =
        (lib.optionalString cfg.nfs.enable nfsBootSections)
        + (lib.optionalString (cfg.nfs.enable && cfg.iscsi.enable) "\n\n")
        + (lib.optionalString cfg.iscsi.enable iscsiBootSections);
    in
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
          set iscsi-server ''${gateway}
          set menu-url menu.ipxe
        '';

        "ipxe/menu.ipxe".text = ''
          #!ipxe

          # Auto-boot by MAC address (net0)
          ${allAutobootChecks}

          # Some menu defaults
          set menu-timeout 50000
          set submenu-timeout ''${menu-timeout}

          :start
          menu iPXE Boot Menu
          ${allMenuItems}
          item --gap --             ------------------------- Advanced options ---------------------------------
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

          ${allBootSections}
        '';
      }
      // (
        # Generate NFS kernel and initrd files for each guest
        if cfg.nfs.enable
        then
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
              nfsGuestConfigs
            )
          )
        else {}
      );

    # Open firewall ports
    networking.firewall.allowedTCPPorts =
      [8080]
      ++ lib.optionals cfg.nfs.enable [2049 111 4000 4001 4002 20049];
    networking.firewall.allowedUDPPorts =
      []
      ++ lib.optionals cfg.nfs.enable [2049 111 4000 4001 4002];

    # Load kernel modules for NFS over RDMA
    boot.kernelModules = lib.optionals cfg.nfs.enable ["svcrdma" "xprtrdma"];
  };
}
