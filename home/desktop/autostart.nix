{
  config,
  pkgs,
  home,
  ...
}: {
  services.autostart = {
    enable = true;
    programs = [
      {
        name = "org.qbittorrent.qBittorrent";
        pkg = pkgs.qbittorrent;
      }
    ];
  };
}
