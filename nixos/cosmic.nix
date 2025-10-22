{
  pkgs,
  username,
  ...
}: {
  services.blueman.enable = true;

  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
}
