{pkgs, ...}: {
  programs = {
    firefox = {
      enable = true;
      enableGnomeExtensions = false;
      # package = pkgs.firefox-wayland; # firefox with wayland support
    };

    vscode = {
      enable = true;
    };
  };
}
