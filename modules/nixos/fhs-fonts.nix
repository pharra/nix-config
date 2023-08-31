{
  config,
  lib,
  pkgs,
  ...
}: let
  mkRoSymBind = path: {
    device = path;
    fsType = "fuse.bindfs";
    options = ["ro" "resolve-symlinks" "x-gvfs-hide"];
  };
  aggregatedFonts = pkgs.buildEnv {
    name = "system-fonts";
    paths = config.fonts.packages;
    pathsToLink = ["/share/fonts"];
  };
  icons = [pkgs.papirus-icon-theme pkgs.breeze-icons];
  iconDir = pkgs.runCommand "icons" {preferLocalBuild = true;} ''
    mkdir -p "$out/share/icons"
    ${lib.concatMapStrings (p: ''
        if [ -d "${p}/share/icons" ]; then
            find -L "${p}/share/icons" -mindepth 1 -maxdepth 1 -type d -exec cp -rn --no-preserve=mode,ownership {}/ "$out/share/icons" \;
        fi
      '')
      icons}
  '';
in {
  ###################################################################################
  #
  #  Copy from https://github.com/NixOS/nixpkgs/issues/119433#issuecomment-1326957279
  #  Mainly for flatpak
  #    1. bindfs resolves all symlink,
  #    2. allowing all fonts to be accessed at `/usr/share/fonts`
  #    3. without letting /nix into the sandbox.
  #
  ###################################################################################
  environment.systemPackages = [iconDir];
  system.fsPackages = [pkgs.bindfs];

  # Create an FHS mount to support flatpak host icons/fonts
  fileSystems."/usr/share/icons" = mkRoSymBind "${iconDir}/share/icons";
  fileSystems."/usr/share/fonts" = mkRoSymBind (aggregatedFonts + "/share/fonts");
}
