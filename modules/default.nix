# 模块清单（显式）：一行一项。加模块就在这里加一行，`ls modules/` 只是目录，不代表被加载。
#
# 求值顺序 = 属性名排序（NixOS 的 list 型选项按模块顺序合并，所以清单顺序就是合并顺序）。
# 以 _ 开头的目录（如 _template）不在这里，所以不会被加载。
{
  amd-gpu-edid-fix = import ./hardware/amd-gpu-edid-fix;
  archlinux = import ./vm/archlinux;
  audio-relay = import ./desktop/audio-relay;
  azure-tools = import ./core/azure-tools;
  backup = import ./storage/backup;
  boot-over-nfs = import ./boot/netboot/boot-over-nfs;
  boot-over-nvmf = import ./boot/netboot/boot-over-nvmf;
  common = import ./core/common;
  cosmic = import ./desktop/cosmic;
  deepseek-harness = import ./desktop/deepseek-harness;
  denial = import ./desktop/denial;
  desktop = import ./core/desktop;
  dms = import ./desktop/dms;
  dhcp-server = import ./network/dhcp-server;
  docker-netns = import ./network/docker-netns;
  easytier = import ./network/easytier;
  flatpak = import ./desktop/flatpak;
  impermanence = import ./core/impermanence;
  input-method = import ./desktop/input-method;
  ipxe-host = import ./boot/netboot/ipxe-host;
  iscsi-root = import ./boot/netboot/iscsi-root;
  kde = import ./desktop/kde;
  kmscon = import ./desktop/kmscon;
  kwallet-shim = import ./desktop/kwallet-shim;
  lianli-linux = import ./hardware/lianli-linux;
  libvirt = import ./vm/libvirt;
  mcontrolcenter = import ./hardware/mcontrolcenter;
  mihomo = import ./network/mihomo;
  mlx5 = import ./hardware/mlx5;
  net-name = import ./network/net-name;
  netns = import ./network/netns;
  net-sriov = import ./hardware/net-sriov;
  network-bridge = import ./network/network-bridge;
  no-desktop = import ./core/no-desktop;
  nvme-auto = import ./hardware/nvme-auto;
  nvmf = import ./boot/netboot/nvmf;
  openwrt = import ./network/openwrt;
  scripts = import ./core/scripts;
  sftp-server = import ./network/sftp-server;
  spdk-container = import ./storage/spdk-container;
  udev-symlink = import ./hardware/udev-symlink;
  user-group = import ./core/user-group;
  vfio = import ./vm/vfio;
  virtualisation = import ./vm/virtualisation;
  waydroid = import ./vm/waydroid;
  weflow = import ./desktop/weflow;
  zfs-config = import ./storage/zfs-config;
}
