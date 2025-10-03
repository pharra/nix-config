{pkgs, ...}: {
  imports = [
    #./immutable-file.nix
    ./media.nix
    ./xdg.nix
    ./looking-glass.nix
    ./autostart.nix
  ];

  home.packages = with pkgs; [
    # GUI apps
    insomnia # REST client
    wireshark # network analyzer

    # remote desktop(rdp connect)
    remmina
    freerdp # required by remmina

    # misc
    flameshot

    (microsoft-edge.overrideAttrs (oldAttrs: rec {
      buildInputs = oldAttrs.buildInputs ++ [makeWrapper];
      postInstall = (oldAttrs.postInstall or "") + "wrapProgram $out/bin/microsoft-edge --add-flags \"--enable-features=AcceleratedVideoDecodeLinuxGL\"";
    }))
  ];

  # GitHub CLI tool
  programs.gh = {
    enable = true;
  };
}
