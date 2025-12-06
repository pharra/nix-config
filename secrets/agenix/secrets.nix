let
  homelab = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPsMIjAmPitKTYN83DxrN/D783BTMkknEuwMeO5s0ABw wf@homelab";
  microsoft_vm = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+W5LW0yB3qzvI8NEnPLsV704FyGiy4Fv5yiZ/VHCFe wf@nixos";
  azure_vm = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ/IRGPdWpQ9iT1bdm51hWhTkv3hwNjEjR8SArP6ni/U wf@jp";
  systems = [homelab microsoft_vm azure_vm];
in {
  "caddy_server_conf.age".publicKeys = systems;
  "xray_server_conf.age".publicKeys = systems;
  "hysteria_server_conf.age".publicKeys = systems;
  "singbox_server_conf.age".publicKeys = systems;

  "caddy_homelab_conf.age".publicKeys = [homelab];
  "wireguard_homelab_private_key.age".publicKeys = [homelab];
  "tailscale_authkey.age".publicKeys = [homelab];
  "restic_password.age".publicKeys = [homelab];
  "rclone_config.age".publicKeys = [homelab];
  "atticd.env".publicKeys = [homelab];
}
