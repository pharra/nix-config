{
  lib,
  stdenv,
  makeWrapper,
  podman,
}:
stdenv.mkDerivation rec {
  pname = "distrobox-session";
  version = "1.1.0";

  src = [
  ];
  phases = ["installPhase"];

  buildInputs = [
    podman
  ];

  installPhase = ''
    mkdir -p $out/share/wayland-sessions
    cat > $out/share/wayland-sessions/plasma-distrobox.desktop << EOF
    [Desktop Entry]
    Exec=${podman}/bin/podman exec -it archlinux su - wf -c "XDG_RUNTIME_DIR=/run/user/1000 /usr/sbin/dbus-run-session /usr/bin/startplasma-wayland"
    DesktopNames=KDE
    Name=Plasma-distrobox
    X-KDE-PluginInfo-Version=5.23.3
  '';

  passthru = {
    providedSessions = ["plasma-distrobox"];
  };

  meta = with lib; {
    description = "distrobox session";
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = [];
  };
}
