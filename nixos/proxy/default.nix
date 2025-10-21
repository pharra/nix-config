{
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [./mihomo];

  services.v2raya.enable = false;
  services.v2raya.cliPackage = pkgs.xray;
  services.mihomo = lib.mkIf config.services.mihomo.enable {
    tunMode = true;
    webui = pkgs.metacubexd;
  };

  programs.sparkle = {
    enable = true;
    tunMode = true; # enable tun mode
    autoStart = true;
  };

  programs.nekoray = {
    enable = true;
    tunMode.enable = true; # enable tun mode
  };
}
