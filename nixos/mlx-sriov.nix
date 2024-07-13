{
  lib,
  pkgs,
  config,
  pkgs-2305,
  ...
}: {
  # environment.etc = {
  #   "modprobe.d/mlx4_core.conf".text = ''
  #     options mlx4_core port_type_array=1,2 num_vfs=8 probe_vf=8 msi_x=1 enable_4k_uar=1 enable_qos=1 log_num_mac=7 log_num_mgm_entry_size=-1 log_mtts_per_seg=4
  #   '';
  # };

  # services.udev.extraRules = ''
  #   ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x15b3", ATTR{device}=="0x1017", ATTR{sriov_drivers_autoprobe}="0"

  #   ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x15b3", ATTR{device}=="0x1017", ATTR{sriov_numvfs}="8"
  # '';
}
