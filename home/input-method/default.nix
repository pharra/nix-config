{
  pkgs,
  lib,
  config,
  utils,
  ...
} @ args: {
  imports = [
    ./fcitx5.nix
    # ./ibus.nix
  ];
}
