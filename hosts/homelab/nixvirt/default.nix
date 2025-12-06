{
  lib,
  pkgs,
  config,
  NixVirt,
  ...
} @ args: let
  ArchLinux = import ./ArchLinux.nix args;
  Windows = import ./Windows.nix args;
  FnOS = import ./FnOS.nix args;
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
      ArchLinux
      Windows
      FnOS
    ];
    pools = [
    ];
  };

  virtualisation.libvirtd.hooks.qemu."10-cpu-manager" = pkgs.writeShellScript "cpu-qemu-hook" ''
    machine=$1
    command=$2
    # Dynamically VFIO bind/unbind the USB with the VM starting up/stopping
    if [ "$machine" == "Windows" ]; then
      if [ "$command" == "prepare" ]; then
        echo "preparing"
      elif [ "$command" == "started" ]; then
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=0-3,12-19,28-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=0-3,12-19,28-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.scope AllowedCPUs=0-3,12-19,28-31
      elif [ "$command" == "stopped" ]; then
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=0-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=0-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.scope AllowedCPUs=0-31
      fi
    fi
  '';

  systemd.services.resize-bar = {
    enable = false;
    script = ''
      set -e
      echo -n "0000:41:00.0" | tee /sys/bus/pci/drivers/vfio-pci/unbind
      echo 15 | tee /sys/bus/pci/devices/0000\:41\:00.0/resource1_resize
      echo -n "0000:41:00.0" | tee /sys/bus/pci/drivers/vfio-pci/bind
    '';
    wantedBy = ["multi-user.target"];
    before = ["libvirtd.service"];
    serviceConfig = {
      Type = "oneshot";
    };
  };

  #services.udev.extraRules = ''
  #  # RTX 4090
  #  ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{device}=="0x2684", ATTR{resource1_resize}="15"
  #'';
}
