{
  config,
  pkgs,
  lib,
  ...
}: {
  # Enable the OpenSSH daemon.
  services.openssh = {
    extraConfig = ''
      Match Group sftp
        ChrootDirectory /share
        ForceCommand internal-sftp # only sftp
        PasswordAuthentication no
    '';
  };

  users.groups = {
    sftp = {};
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.sftp = {
    isSystemUser = true;
    initialHashedPassword = lib.mkForce "$y$j9T$.E302ulZwh842trRJ9vVK1$VWgxXPL1csOBZopSN.7aah.Ia4cSifk8NOr4xSRV1D4";
    group = "sftp";
    useDefaultShell = true;
    openssh.authorizedKeys.keys = [
      # sftp public key
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDoToM2NT33ERHUt0g99EsvZArlg4mYO2oHcAuHs6Rgu wf@homelab"
    ];
  };
}
