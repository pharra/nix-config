{
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [./config];
  # config = lib.mkIf config.services.mihomo.enable {
  #   services.mihomo = {
  #     tunMode = true;
  #     webui = pkgs.metacubexd;
  #   };
  # };
  services.v2raya.enable = true;
  services.v2raya.cliPackage = pkgs.xray;
  services.mihomo = {
    enable = false;
    tunMode = true;
    webui = pkgs.metacubexd;
  };
}
