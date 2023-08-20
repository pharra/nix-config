{
  lib,
  pkgs,
  username,
  config,
  ...
}: {
  environment.etc = {
    "modprobe.d/mlx4_core.conf".text = ''
      options mlx4_core port_type_array=2,2 num_vfs=8 probe_vf=8 msi_x=1 enable_4k_uar=1 enable_qos=1 log_num_mac=7 log_num_mgm_entry_size=-1 log_mtts_per_seg=4
    '';
  };
}
