let
  homelab = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPsMIjAmPitKTYN83DxrN/D783BTMkknEuwMeO5s0ABw wf@homelab";
  azure_vm = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ/IRGPdWpQ9iT1bdm51hWhTkv3hwNjEjR8SArP6ni/U wf@jp";
  systems = [homelab azure_vm];
in {
  "caddy_server_conf.age".publicKeys = systems;
  "xray_server_conf.age".publicKeys = systems;

  "restic_password.age".publicKeys = [homelab];
  "rclone_config.age".publicKeys = [homelab];
}
