{
  lib,
  pkgs,
  config,
  NixVirt,
  ...
} @ args: let
  Windows = import ./Windows.nix args;
  Microsoft = import ./Microsoft.nix args;
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
      # Microsoft
      Linux
    ];
    pools = [
      {
        definition = NixVirt.lib.pool.writeXML {
          name = "VMPool";
          uuid = "650c5bbb-eebd-4cea-8a2f-36e1a75a8683";
          type = "dir";
          target = {path = "/fluent/VMPool";};
          active = true;
        };
      }

      {
        definition = NixVirt.lib.pool.writeXML {
          name = "RAMPool";
          uuid = "650c5bbb-eebd-4cea-8a2f-36e1a75a8685";
          type = "dir";
          target = {path = "/fluent/RAMPool";};
          active = true;
        };
      }

      {
        definition = NixVirt.lib.pool.writeXML {
          name = "ISOPool";
          uuid = "650c5bbb-eebd-4cea-8a2f-36e1a75a8684";
          type = "dir";
          target = {path = "/home/wf/Data/ISOPool";};
          active = true;
        };
      }

      {
        definition = NixVirt.lib.pool.writeXML {
          name = "DiskPool";
          uuid = "650c5bbb-eebd-4cea-8a2f-36e1a75a8686";
          type = "dir";
          target = {path = "/fluent/DiskPool";};
          active = true;
        };
      }
    ];
  };

  virtualisation.libvirtd.hooks.qemu."10-cpu-manager" = pkgs.writeShellScript "cpu-qemu-hook" ''
    machine=$1
    command=$2
    if [ "$machine" == "Windows" ]; then
      if [ "$command" == "prepare" ]; then
        ${pkgs.coreutils-full}/bin/echo "preparing"
      elif [ "$command" == "started" ]; then
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=8-15,24-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=8-15,24-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.scope AllowedCPUs=8-15,24-31
      elif [ "$command" == "stopped" ]; then
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=0-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=0-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.scope AllowedCPUs=0-31
      fi
    fi
  '';
}
