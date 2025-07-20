self: super: {
  deepin = super.deepin.overrideScope (deepinself: deepinsuper: {
    deepin-icon-theme = deepinsuper.deepin-icon-theme.overrideAttrs (oldAttrs: {
      dontWrapQtApps = true;
    });

    deepin-desktop-theme = deepinsuper.deepin-desktop-theme.overrideAttrs (oldAttrs: {
      dontWrapQtApps = true;
    });
  });
}
