{
  config,
  pkgs,
  lib,
  username,
  ...
}:
with builtins;
with lib; {
  wsl = {
    enable = true;
    defaultUser = username;
    startMenuLaunchers = true;
    useWindowsDriver = true;

    interop.register = true;
    wslConf.interop.enabled = true;
    wslConf.interop.appendWindowsPath = true;

    # Fixes VSCode not being able to run.
    extraBin = [
      # Required by VS Code's Remote WSL extension
      {src = "${pkgs.coreutils}/bin/dirname";}
      {src = "${pkgs.coreutils}/bin/readlink";}
      {src = "${pkgs.coreutils}/bin/uname";}
    ];
  };

  users.allowNoPasswordLogin = true;

  environment.systemPackages = with pkgs; [wslu];

  programs.nix-ld = {
    enable = true;
    libraries = [
      # Required by NodeJS installed by VS Code's Remote WSL extension
      pkgs.stdenv.cc.cc
    ];
  };

  # Fixes Home-Manager applications not appearing in Start Menu
  system.activationScripts.copy-user-launchers = stringAfter [] ''
    for x in applications icons; do
      echo "setting up /usr/share/''${x}..."
      targets=()
      if [[ -d "/etc/profiles/per-user/${config.wsl.defaultUser}/share/$x" ]]; then
        targets+=("/etc/profiles/per-user/${config.wsl.defaultUser}/share/$x/.")
      fi

      if (( ''${#targets[@]} != 0 )); then
        mkdir -p "/usr/share/$x"
        ${pkgs.rsync}/bin/rsync -ar --delete-after "''${targets[@]}" "/usr/share/$x"
      else
        rm -rf "/usr/share/$x"
      fi
    done
  '';

  environment.sessionVariables = {
    CUDA_PATH = "${pkgs.cudatoolkit}";
    EXTRA_LDFLAGS = "-L/lib -L${pkgs.linuxPackages.nvidia_x11_latest}/lib";
    EXTRA_CCFLAGS = "-I/usr/include";
    LD_LIBRARY_PATH = [
      "/usr/lib/wsl/lib"
      "/run/opengl-driver/lib"
      "${pkgs.linuxPackages.nvidia_x11_latest}/lib"
      "${pkgs.ncurses5}/lib"
    ];
    NIX_LD_LIBRARY_PATH_x86_64_linux = [
      "/usr/lib/wsl/lib"
      "/run/opengl-driver/lib"
    ];
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
      config.hardware.graphics.package
      libvdpau-va-gl
      libva-vdpau-driver
      libva
    ];
    extraPackages32 = with pkgs; [
      driversi686Linux.mesa
      config.hardware.graphics.package32
      driversi686Linux.libvdpau-va-gl
      driversi686Linux.libva-vdpau-driver
    ];
  };
}
