{
  config,
  pkgs,
  lib,
  ...
}: {
  services.sftpgo = {
    enable = true;

    settings = {
      httpd.bindings = [
        {
          port = 8888;
        }
      ];
      sftpd.bindings = [
        {
          address = "";
          port = 23269;
        }
      ];
    };
  };

  systemd.services.sftpgo.serviceConfig =
    lib.mkForce
    {
      Type = "simple";
      User = "sftpgo";
      Group = "sftpgo";
      WorkingDirectory = "/var/lib/sftpgo";
      LimitNOFILE = 8192; # taken from upstream
      KillMode = "mixed";
      ExecStart = "${pkgs.sftpgo}/bin/sftpgo serve";
      ExecReload = "${pkgs.util-linux}/bin/kill -s HUP $MAINPID";
    };
}
