{
  lib,
  pkgs,
  config,
  NixVirt,
  ...
}: {
  imports = [
    ./Oct.nix
    ./Pat.nix
  ];

  environment = {
    systemPackages = with pkgs; [
      NixVirt.packages.x86_64-linux.default
    ];
  };

  virtualisation.libvirt.enable = true;
  virtualisation.libvirt.verbose = true;
}
