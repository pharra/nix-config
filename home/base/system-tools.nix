{pkgs, ...}: {
  # Linux Only Packages, not available on Darwin
  home.packages = with pkgs; [
    btop

    # misc
    libnotify
    wireguard-tools # manage wireguard vpn manually, via wg-quick

    # system call monitoring
    strace # system call monitoring
    ltrace # library call monitoring
    lsof # list open files

    # system tools
    sysstat
    lm_sensors # for `sensors` command
    ethtool
    pciutils # lspci
    usbutils # lsusb
    dmidecode # a tool that reads information about your system's hardware from the BIOS according to the SMBIOS/DMI standard
    fio # disk performance

    dnsutils
  ];
}
