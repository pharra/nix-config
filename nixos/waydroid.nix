{
  config,
  pkgs,
  ...
}: {
  virtualisation.waydroid.enable = true;

  environment.systemPackages = with pkgs; [
    android-tools
    scrcpy
    python3
  ];
}
