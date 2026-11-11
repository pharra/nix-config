{
  config,
  lib,
  username,
  ...
}:
with lib; let
  cfg = config.services.pharra.impermanence;
in {
  options = {
    services.pharra.impermanence = {
      enable = mkEnableOption "impermanence support";
    };
  };

  config = mkIf cfg.enable {
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

        {
          directory = "/home/${username}";
          user = "${username}";
          group = "${username}";
          mode = "u=rwx,g=r,o=";
        }
      ];
      files = [
        "/etc/machine-id"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/root/.zsh_history"
      ];
    };

    # age.identityPaths = ["/nix/persistent/etc/ssh/ssh_host_ed25519_key"];

    fileSystems."/" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = ["relatime" "mode=755" "nosuid" "nodev"];
    };
  };
}
