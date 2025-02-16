{pkgs, ...}: {
  imports = [
    #./immutable-file.nix
    ./media.nix
    ./ssh.nix
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

    code-cursor
  ];

  # GitHub CLI tool
  programs.gh = {
    enable = true;
  };
}
