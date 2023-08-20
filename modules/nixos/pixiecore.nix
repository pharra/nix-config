{
  lib,
  pkgs,
  config,
  libs,
  ...
}: {
  services.pixiecore = {
    enable = true;
    mode = "quick";
    quick = "debian";
    #listen = "192.168.30.1";
    dhcpNoBind = true;
    extraArguments = ["stable"];
  };
}
