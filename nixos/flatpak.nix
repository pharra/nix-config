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

  nixpkgs.overlays = [
    (self: super: {
      flatpak = super.flatpak.overrideAttrs (oldAttrs: rec {
        buildInputs = oldAttrs.buildInputs ++ [super.makeWrapper];
        postInstall = (oldAttrs.postInstall or "") + "wrapProgram $out/bin/flatpak --set LANGUAGE zh_CN";
      });
    })
  ];

  # https://flatpak.org/setup/NixOS
  services.flatpak.enable = true;
}
