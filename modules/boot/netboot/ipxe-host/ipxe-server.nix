# iPXE 服务侧：静态 web 服务 + 菜单/引导脚本模板 + 防火墙端口。
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.pharra.ipxe-host;
  nfsGuestConfigs = import ./guests.nix {inherit lib cfg;};
in {
  config = mkIf cfg.enable {
    # Setup static web server for iPXE assets
    services.static-web-server = {
      enable = true;
      listen = "[::]:8080";
      root = "/etc/ipxe";
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
        "ipxe/snponly.efi".source = ./snponly.efi;

        "ipxe/boot.ipxe".text = ''
          #!ipxe
          chain --autofree boot.ipxe.cfg ||
          chain --replace --autofree ''${menu-url} ||
        '';

        "ipxe/boot.ipxe.cfg".text = ''
          #!ipxe
          set http-server ''${dhcp-server}
          set nfs-server ''${dhcp-server}
          set iscsi-server ''${dhcp-server}
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
  };
}
