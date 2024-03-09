{
  lib,
  pkgs,
  username,
  config,
  ...
}: {
  ###################################################################################
  #
  #  Enable flatpak
  #
  ###################################################################################

  # https://flatpak.org/setup/NixOS
  services.flatpak.enable = true;

  services.flatpak.packages = [
    {
      appId = "com.microsoft.Edge";
      origin = "flathub";
    }
    {
      appId = "org.localsend.localsend_app";
      origin = "flathub";
    }
    {
      appId = "com.qq.QQ";
      origin = "flathub";
    }
  ];
}
