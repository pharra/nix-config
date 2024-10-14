{
  stdenv,
  fetchurl,
  rustPlatform,
  pkg-config,
  dbus,
}:
rustPlatform.buildRustPackage rec {
  name = "surface-dtx-daemon";
  version = "0.3.8-1";
  src = fetchurl {
    url = "https://github.com/linux-surface/surface-dtx-daemon/archive/v${version}.tar.gz";
    sha256 = "sha256-Hb5+cz/9omCtjnfSZxRWz7gUgBqFRXrEI5sKDApt2ss=";
  };

  buildInputs = [pkg-config dbus];
  nativeBuildInputs = [pkg-config dbus];
  cargoLock = {
    lockFile = ./Cargo.lock;
    allowBuiltinFetchGit = true;
  };

  postPatch = ''
    cp ${./Cargo.lock} Cargo.lock
  '';

  postInstall = ''
    mkdir -p $out/etc/udev/rules.d
    cp etc/udev/40-surface_dtx.rules $out/etc/udev/rules.d/

    mkdir -p $out/etc/dbus-1/system.d
    cp etc/dbus/org.surface.dtx.conf $out/etc/dbus-1/system.d/

    mkdir -p $out/etc/dtx
    cp etc/dtx/*.conf $out/etc/dtx/
  '';
}
