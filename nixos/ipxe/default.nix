{
  lib,
  pkgs,
  config,
  libs,
  interface,
  netboot_args ? false,
  ...
}:
lib.mkIf (netboot_args != false)
(let
  netboot_installer = netboot_args.netboot_installer;
in {
  environment.systemPackages = with pkgs; [
    ipxe
  ];

  environment.etc = {
    "ipxe/ipxe.efi" = {
      source = pkgs.ipxe + "/ipxe.efi";
    };

    "ipxe/undionly.kpxe" = {
      source = pkgs.ipxe + "/undionly.kpxe";
    };

    # "ipxe/netboot/bzImage" = {
    #   source = netboot_installer.config.system.build.kernel + "/bzImage";
    # };

    # "ipxe/netboot/initrd" = {
    #   source = netboot_installer.config.system.build.netbootRamdisk + "/initrd";
    # };

    "ipxe/boot.ipxe".text = ''
      #!ipxe

      # Global variables used by all other iPXE scripts
      chain --autofree boot.ipxe.cfg ||

      # Boot <boot-url>/menu.ipxe script if all other options have been exhausted
      chain --replace --autofree ''${menu-url} ||
    '';

    "ipxe/boot.ipxe.cfg".text = ''
      #!ipxe

      # OPTIONAL: NFS server used for menu files and other things
      # Must be specified as IP, as some distros don't do proper name resolution
      set nfs-server ''${gateway}
      set nfs-root /export/test/

      set http-server ''${gateway}

      # OPTIONAL: Base URL used to resolve most other resources
      # Should always end with a slash
      #set boot-url http://boot.smidsrod.lan/
      set boot-url nfs://''${nfs-server}''${nfs-root}

      set iscsi-server ''${gateway}
      #set base-iqn iqn.2003-01.org.linux-iscsi.homelab.x8664
      set base-iqn iqn.2016-06.io.spdk
      #set base-iscsi iscsi:''${iscsi-server}:::1:''${base-iqn}
      set base-iscsi iscsi:''${iscsi-server}::::''${base-iqn}
      isset ''${hostname} && set initiator-iqn ''${base-iqn}:''${hostname} || set initiator-iqn ''${base-iqn}:''${mac}

      # REQUIRED: Absolute URL to the menu script, used by boot.ipxe
      # and commonly used at the end of simple override scripts
      # in ''${boot-dir}.
      set menu-url menu.ipxe
    '';

    "ipxe/menu.ipxe".text = ''
      #!ipxe

      # Variables are specified in boot.ipxe.cfg

      # boot on fluent
      set fluent_mac:hex 9c:52:f8:8e:dd:d8
      set net0
      iseq ''${net0/mac} ''${fluent_mac} && goto fluent_nixos ||

      # Some menu defaults
      set menu-timeout 50000
      set submenu-timeout ''${menu-timeout}

      goto start

      ###################### MAIN MENU ####################################

      :start
      menu iPXE boot menu
      item --gap --             ------------------------- Operating systems ------------------------------
      item nixos      Boot NixOS
      item fluent_nixos      Boot NixOS on fluent
      # item nixos-installer Boot NixOS Installer
      item win      Boot Windows
      item win-install      Boot Windows Installer
      item --gap --             ------------------------- Advanced options -------------------------------
      item --key c config       Configure settings
      item shell                Drop to iPXE shell
      item reboot               Reboot computer
      item
      item --key x exit         Exit iPXE and continue BIOS boot
      choose --default exit --timeout ''${menu-timeout} target && goto ''${target}

      :cancel
      echo You cancelled the menu, dropping you to a shell

      :shell
      echo Type 'exit' to get the back to the menu
      shell
      set menu-timeout 0
      set submenu-timeout 0
      goto start

      :failed
      echo Booting failed, dropping to shell
      goto shell

      :reboot
      reboot

      :exit
      exit

      :config
      config
      goto start

      :back
      set submenu-timeout 0
      clear submenu-default
      goto start

      ############ MAIN MENU ITEMS ############
      :nixos
      echo Booting nixos from iSCSI for ''${initiator-iqn}
      set root-path ''${base-iscsi}:nixosefi
      sanboot --drive 0x80 ''${root-path} || goto failed

      :fluent_nixos
      echo Booting nixos from iSCSI for ''${initiator-iqn}
      set root-path ''${base-iscsi}:fluentnixosefi
      sanboot --drive 0x80 ''${root-path} || goto failed

      # :nixos-installer
      # echo Booting nixos installer
      # kernel netboot/bzImage init=${netboot_installer.config.system.build.toplevel}/init ${toString netboot_installer.config.boot.kernelParams}
      # initrd netboot/initrd
      # boot

      :win
      echo Booting windows from iSCSI for ''${initiator-iqn}
      # Force gateway to be the iSCSI target selib.mkIf (netboot_args != false) rver (kludge for stupid window behavior)
      # set netX/gateway ''${iscsi-server}
      # set net0/gateway 0.0.0.0
      set root-path ''${base-iscsi}:data
      sanboot --drive 0x80 ''${root-path} || goto failed
      #sanhook --drive 0x81 ''${base-iscsi}:wina || goto failed

      :win-install
      echo Booting windows from iSCSI for ''${initiator-iqn}
      # Force gateway to be the iSCSI target server (kludge for stupid window behavior)
      # set netX/gateway ''${iscsi-server}
      kernel wimboot
      # set net0/gateway 0.0.0.0
      #set root-path ''${base-iscsi}:win
      sanhook --drive 0x80 ''${base-iscsi}:data || goto failed
      #sanhook --drive 0x81 ''${base-iscsi}:wina || goto failed
      initrd bootmgr      bootmgr
      initrd bootmgr.efi  bootmgr.efi
      initrd bootx64.efi  bootx64.efi
      initrd BCD          BCD$
    '';

    # "ipxe/wimboot" = {
    #   source = ./wimboot;
    # };
    # "ipxe/boot.wim" = {
    #   source = ./boot.wim;
    # };
    # "ipxe/BCD" = {
    #   source = ./BCD;
    # };
    # "ipxe/boot.sdi" = {
    #   source = ./boot.sdi;
    # };
    # "ipxe/bootmgr" = {
    #   source = ./bootmgr;
    # };
    # "ipxe/bootmgr.efi" = {
    #   source = ./bootmgr.efi;
    # };
    # "ipxe/bootx64.efi" = {
    #   source = ./bootx64.efi;
    # };
  };

  services.static-web-server = {
    enable = true;
    root = "/etc/ipxe";
  };

  # services.dnsmasq = {
  #   enable = false;
  #   settings = {
  #     interface = "${interface.ib},${interface.eth},${interface.intern}";
  #     enable-tftp = true;
  #     dhcp-range = ["interface:${interface.ib},192.168.30.50,192.168.30.150" "interface:${interface.eth},192.168.29.50,192.168.29.150" "interface:${interface.intern},192.168.28.50,192.168.28.150"];
  #     listen-address = "192.168.30.1,192.168.29.1,192.168.28.1";
  #     bind-interfaces = true;
  #     log-dhcp = true;
  #     tftp-root = "/etc/ipxe";
  #     dhcp-match = "set:ipxe,175";
  #     dhcp-boot = ["tag:!ipxe,ipxe.efi" "tag:ipxe,boot.ipxe"];
  #     # local = "/intern/";
  #     # domain = "intern";
  #     # expand-hosts = true;
  #     localise-queries = true;
  #     host-record = ["homelab.intern,192.168.30.1" "homelab.intern,192.168.29.1" "homelab.intern,192.168.28.1"];
  #   };
  # };

  # services.pixiecore = {
  #   enable = true;
  #   listen = "192.168.31.200";
  #   kernel = netboot_installer.config.system.build.kernel + "/bzImage";
  #   initrd = netboot_installer.config.system.build.netbootRamdisk + "/initrd";
  #   dhcpNoBind = true;
  #   cmdLine = "init=${netboot_installer.config.system.build.toplevel}/init ${toString netboot_installer.config.boot.kernelParams}";
  # };
})
