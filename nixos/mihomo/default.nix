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

  services.mihomo = {
    enable = true;
    tunMode = true;
    webui = pkgs.metacubexd;
  };
}
