{
  pkgs,
  lib,
  config,
  utils,
  inputs,
  ...
} @ args: {
  environment.systemPackages = with pkgs; [
    aosp
  ];
}
