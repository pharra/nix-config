{
  lib,
  pkgs,
  config,
  NixVirt,
  ...
} @ args: let
  Windows = import ./Oct.nix args;
  Pat = import ./Pat.nix args;
  Linux = import ./Linux.nix args;
in {
  environment = {
    systemPackages = with pkgs; [
      NixVirt.packages.x86_64-linux.default
    ];
  };

  virtualisation.libvirt.enable = true;
  virtualisation.libvirt.verbose = true;
  virtualisation.libvirt.connections."qemu:///system" = {
    domains = [
      Windows
      Pat
      Linux
    ];
  };

  virtualisation.libvirtd.hooks.qemu."10-cpu-manager" = pkgs.writeShellScript "cpu-qemu-hook" ''
    machine=$1
    command=$2
    log_tag="libvirt-hook"
    log() {
      ${pkgs.util-linux}/bin/logger -t "$log_tag" "$1"
    }

    log "qemu hook invoked: machine=$machine command=$command"

    if [ "$machine" == "Pat" ]; then
      if [ "$command" == "prepare" ]; then
        log "Pat: preparing"
      elif [ "$command" == "started" ]; then
        log "Pat: applying dedicated CPU mask (8-15,24-31)"
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=8-15,24-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=8-15,24-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.scope AllowedCPUs=8-15,24-31
        log "Pat: dedicated CPU mask applied"
      elif [ "$command" == "stopped" ]; then
        log "Pat: restoring full CPU mask (0-31)"
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=0-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=0-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.scope AllowedCPUs=0-31
        log "Pat: full CPU mask restored"
      else
        log "Pat: unhandled command=$command"
      fi
    else
      log "ignoring machine=$machine command=$command"
    fi
  '';
}
