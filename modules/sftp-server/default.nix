{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.pharra.sftp-server;
in {
  options = {
    services.pharra.sftp-server = {
      enable = mkEnableOption "SFTP server in container";
    };
  };

  config = mkIf cfg.enable {
    containers.sftp-server = {
      autoStart = true;
      privateUsers = "no";
      privateNetwork = false;
      bindMounts = {
        "/share" = {
          hostPath = "/share";
          isReadOnly = false;
        };
      };
      config = {
        config,
        pkgs,
        lib,
        ...
      }: {
        # Enable the OpenSSH daemon.
        services.openssh = {
          enable = true;
          ports = [23268];
          settings = {
            X11Forwarding = true;
            PermitRootLogin = "no"; # disable root login
            PasswordAuthentication = false; # disable password login
          };
          # Enable the OpenSSH daemon.
          # The owner of the SFTP directory must be root, and the maximum allowed permission is 755; otherwise, even if the directory is owned by the SFTP user, an error will occur.
          extraConfig = ''
            Match User sftp
              ChrootDirectory /share
              ForceCommand internal-sftp # only sftp
              PasswordAuthentication no
          '';
          openFirewall = true;
        };

        users.groups = {
          sftp = {
            gid = 1000;
          };
          users = {
            gid = 100;
          };
        };

        # Define a user account. Don't forget to set a password with 'passwd'.
        users.users.sftp = {
          isSystemUser = true;
          uid = 1000;
          initialHashedPassword = lib.mkForce "$y$j9T$.E302ulZwh842trRJ9vVK1$VWgxXPL1csOBZopSN.7aah.Ia4cSifk8NOr4xSRV1D4";
          group = "users";
          useDefaultShell = true;
          openssh.authorizedKeys.keys = [
            # wf public key
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDoToM2NT33ERHUt0g99EsvZArlg4mYO2oHcAuHs6Rgu wf@homelab"
          ];
        };

        system.stateVersion = "25.05";
      };
    };
  };
}
