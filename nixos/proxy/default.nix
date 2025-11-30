{
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [./mihomo];

  services.mihomo = lib.mkIf config.services.mihomo.enable {
    tunMode = true;
    webui = pkgs.metacubexd;
  };

  programs.sparkle = {
    enable = true;
    tunMode = true; # enable tun mode
    autoStart = true;
  };

  programs.throne = {
    enable = true;
    tunMode.enable = true; # enable tun mode
  };
}
