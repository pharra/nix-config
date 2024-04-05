self: super: {
  flatpak = super.flatpak.overrideAttrs (oldAttrs: rec {
    buildInputs = oldAttrs.buildInputs ++ [super.makeWrapper];
    postInstall = (oldAttrs.postInstall or "") + "wrapProgram $out/bin/flatpak --set LANGUAGE zh_CN";
  });
}
