{
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [./mihomo];

  services.v2raya.enable = true;
  services.v2raya.cliPackage = pkgs.xray;
  services.mihomo = lib.mkIf config.services.mihomo.enable {
    tunMode = true;
    webui = pkgs.metacubexd;
  };
}
