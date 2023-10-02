{
  config,
  pkgs,
  lib,
  ...
}: {
  environment = {
    systemPackages = with pkgs; [
      sftpgo
    ];
  };
  # Enable the OpenSSH daemon.
  services.openssh = {
    extraConfig = ''
      Match Group sftp
        ChrootDirectory /share
        ForceCommand internal-sftp # only sftp
        PasswordAuthentication yes
    '';
    sftpServerExecutable = "${pkgs.sftpgo}/bin/sftpgo";
  };

  users.groups = {
    sftp = {};
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.sftp = {
    isSystemUser = true;
    hashedPassword = lib.mkForce "$y$j9T$.E302ulZwh842trRJ9vVK1$VWgxXPL1csOBZopSN.7aah.Ia4cSifk8NOr4xSRV1D4";
    initialHashedPassword = lib.mkForce "$y$j9T$.E302ulZwh842trRJ9vVK1$VWgxXPL1csOBZopSN.7aah.Ia4cSifk8NOr4xSRV1D4";
    group = "sftp";
    useDefaultShell = true;
  };
}
