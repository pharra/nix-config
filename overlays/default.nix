{
  # Add your overlays here
  #
  # my-overlay = import ./my-overlay;
  dpdk-overlay = import ./dpdk;
  looking-glass-overlay = import ./looking-glass;
  ipxe-overlay = import ./ipxe;
  qemu-overlay = import ./qemu-vfio-user;
}
