{
  # Add your overlays here
  #
  # my-overlay = import ./my-overlay;
  dpdk-overlay = import ./dpdk;
  looking-glass-overlay = import ./looking-glass;
  ipxe-overlay = import ./ipxe;
  flatpak-overlay = import ./flatpak;
  # qemu-overlay = import ./qemu-vfio-user;
  evdi-overlay = import ./evdi;
  tailscale-overlay = import ./tailscale;
}
