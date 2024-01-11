self: super: {
  flatpak = super.flatpak.overrideAttrs (oldAttrs: rec {
    patches =
      oldAttrs.patches
      ++ [
        ./fix-fonts-icons.patch
      ];

    buildInputs = oldAttrs.buildInputs ++ [super.makeWrapper];
    postInstall = (oldAttrs.postInstall or "") + "wrapProgram $out/bin/flatpak --set LANGUAGE zh_CN";
  });
}
