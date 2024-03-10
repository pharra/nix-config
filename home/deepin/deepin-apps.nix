{pkgs, ...}: {
  services.vscode-server.enable = true;

  programs = {
    firefox = {
      enable = true;
      # enableGnomeExtensions = false;
      # package = pkgs.firefox-wayland; # firefox with wayland support
    };

    vscode = {
      enable = true;
      # use the stable version
      # package = pkgs.vscode.override {
      #   commandLineArgs = [
      #     # make it use text-input-v1, which works for kwin 5.27 and weston
      #     # "--enable-wayland-ime"
      #   ];
      # };

      # let vscode sync and update its configuration & extensions across devices, using github account.
      # userSettings = {};
    };
  };
}
