{
  stdenv,
  lib,
  qtbase,
  wrapQtAppsHook,
  cmake,
  fetchFromGitHub,
  qttools,
  makeDesktopItem,
  pkg-config,
}: let
  desktopItem = makeDesktopItem {
    name = "MControlCenter";
    desktopName = "MSI Control Center";
    type = "Application";
    exec = "mcontrolcenter";
    icon = "mcontrolcenter";
    terminal = false;
    extraConfig = {
      "X-GNOME-Autostart-Delay" = "10";
    };
  };
in
  stdenv.mkDerivation rec {
    pname = "MControlCenter";
    # Release is old and missing features such as setting the battery charging limit
    version = "unstable-2023-01-21";

    buildInputs = [qtbase cmake qttools];
    nativeBuildInputs = [wrapQtAppsHook pkg-config];

    src = fetchFromGitHub {
      owner = "dmitry-s93";
      repo = pname;
      rev = "a23f483faf4ec9190a99c2a1eaf72bce194eefd0";
      sha256 = "sha256-U+k8ONgSSmp6IP2MVYXYVtuxZiFvRGmH3AJcGvzk8WU=";
    };

    postPatch = ''
      patchShebangs .
    '';

    postInstall = ''
      mkdir -p $out/share/pixmaps
      ln -s ${desktopItem}/share/applications $out/share/
      cp $src/resources/mcontrolcenter.svg $out/share/pixmaps

      mkdir -p $out/share/dbus-1/system-services
      cat <<END > $out/share/dbus-1/system-services/mcontrolcenter.helper.service
      [D-BUS Service]
      Name=mcontrolcenter.helper
      Exec=$out/bin/mcontrolcenter-helper
      User=root
      END

      mkdir -p $out/share/dbus-1/system.d
      cp $src/src/helper/mcontrolcenter-helper.conf $out/share/dbus-1/system.d
    '';

    meta = with lib; {
      description = "Fan control tool for MSI gaming series laptops";
      homepage = "https://github.com/dmitry-s93/MControlCenter";
      license = licenses.gpl3Plus;
      maintainers = with maintainers; [];
    };
  }
