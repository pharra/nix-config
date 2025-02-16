self: super: {
  kdePackages =
    super.kdePackages
    // {
      kwin = super.kdePackages.kwin.overrideAttrs (oldAttrs: rec {
        patches = oldAttrs.patches ++ [./kwin_nested.patch];
      });
    };
}
