self: super: {
  linux-wallpaperengine = super.linux-wallpaperengine.overrideAttrs (oldAttrs: rec {
    src = super.fetchFromGitHub {
      owner = "Almamu";
      repo = "linux-wallpaperengine";
      rev = "b016d7d1fdcf4e5fd2f9c9fa420a8aaa07fee02d";
      sha256 = "sha256-ExWAYdSFW5plPuS3/jxTPMXIly6zVb5GojE3e37imZM=";
      fetchSubmodules = true;
    };
    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [super.dbus];
  });
}
