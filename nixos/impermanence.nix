{
  lib,
  pkgs,
  username,
  config,
  ...
}: {
  environment.persistence."/nix/persistent" = {
    hideMounts = true;
    directories = [
      "/var/backup"
      "/var/cache"
      "/var/lib"
      "/var/log"
      "/etc/NetworkManager/system-connections"
      "/etc/ksmbd"
      "/etc/caddy"
      "/etc/v2raya"
      "/etc/cdi"
      #"/smb"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/root/.zsh_history"
    ];

    users.${username} = {
      directories = [
        # Personal folders
        "Desktop"
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Projects"
        "Videos"
        "Data"
        "spdk"

        # Preserved cache
        ".cache/com.github.tchar.calculate-anything" # Ulauncher calculator plugin
        ".cache/mesa_shader_cache" # Intel GPU Shader Cache
        ".cache/netease-cloud-music/Cef" # NetEase Cloud Music Login State
        ".cache/nix-index" # nix-index index data
        ".cache/nvidia" # NVIDIA GPU Shader Cache
        ".cache/tldr-python" # Ulauncher TLDR plugin

        # XDG config folders
        ".config"
        ".local"

        # firefox
        ".mozilla"

        # Important config
        ".gnupg"
        ".ssh"

        # flatpak
        ".var/app"

        # Other configs
        ".android"
        ".steam"
        ".vscode"
        ".vscode-cli"
        ".vscode-server"
        ".cursor"
        ".cursor-cli"
        ".cursor-server"
        ".wine"
      ];
      files = [
        ".zsh_history"
        ".gitconfig"
        ".zshrc"
      ];
    };
  };

  # age.identityPaths = ["/nix/persistent/etc/ssh/ssh_host_ed25519_key"];

  fileSystems."/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = ["relatime" "mode=755" "nosuid" "nodev"];
  };

  # Impermanence will copy permissions from source dir
  # Chown to wf:wf
  systemd.tmpfiles.rules = [
    "d /nix/persistent/home/${username} 700 ${username} ${username}"
  ];
}
