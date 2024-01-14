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

    # instant messaging
    telegram-desktop
    discord
    qq # https://github.com/NixOS/nixpkgs/tree/master/pkgs/applications/networking/instant-messengers/qq

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
