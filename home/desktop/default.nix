{pkgs, ...}: {
  imports = [
    #./immutable-file.nix
    ./media.nix
    ./ssh.nix
    ./xdg.nix
    ./looking-glass.nix
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
  ];

  # GitHub CLI tool
  programs.gh = {
    enable = true;
  };
}
