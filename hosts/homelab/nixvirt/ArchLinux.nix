{NixVirt, ...} @ args: let
  base = import ../../../nixos/nixvirt/base.nix args;
  inherit (base) linux_template;
in {
  definition = let
    ArchLinux = linux_template {
      name = "ArchLinux";
      uuid = "ee43005c-2e7b-4af2-bfae-8c52eeb22672";
      memory = {
        count = 6;
        unit = "GiB";
      };
      storage_vol = /home/wf/Data/VMPool/ArchLinux.qcow2;
      # install_vol = {
      #   pool = "ISOPool";
      #   volume = "archlinux-2024.04.01-x86_64.iso";
      # };
      nvram_path = /home/wf/Data/RAMPool/ArchLinux.fd;
      no_graphics = true;
    };
  in
    NixVirt.lib.domain.writeXML (
      ArchLinux
      // {
        cpu = {
          mode = "host-passthrough";
          check = "none";
          migratable = true;
          topology = {
            sockets = 1;
            dies = 1;
            cores = 2;
            threads = 2;
          };
        };
        devices =
          ArchLinux.devices
          // {
            interface = {
              type = "bridge";
              model = {type = "virtio";};
              source = {bridge = "br1";};
            };
          };
      }
    );
}
