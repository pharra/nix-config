{
  config,
  pkgs,
  lib,
  ...
}: {
  # Enable the OpenSSH daemon.
  # The owner of the SFTP directory must be root, and the maximum allowed permission is 755; otherwise, even if the directory is owned by the SFTP user, an error will occur.
  services.openssh = {
    extraConfig = ''
      Match User sftp
        ChrootDirectory /share
        ForceCommand internal-sftp # only sftp
        PasswordAuthentication no
    '';
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.sftp = {
    isSystemUser = true;
    uid = 989;
    initialHashedPassword = lib.mkForce "$y$j9T$.E302ulZwh842trRJ9vVK1$VWgxXPL1csOBZopSN.7aah.Ia4cSifk8NOr4xSRV1D4";
    group = "users";
    useDefaultShell = true;
    openssh.authorizedKeys.keys = [
      # sftp public key
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDoToM2NT33ERHUt0g99EsvZArlg4mYO2oHcAuHs6Rgu wf@homelab"
    ];
  };
}
