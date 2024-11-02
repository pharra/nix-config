{
  config,
  pkgs,
  username,
  ...
}: {
  # mount a smb/cifs share
  services.rpcbind.enable = true; # needed for NFS

  security.krb5 = {
    enable = true;
    settings = {
      domain_realm."nfs.lan" = "NFS.LAN";
      libdefaults.default_realm = "NFS.LAN";
      realms."NFS.LAN" = {
        admin_server = "homelab.lan";
        kdc = "homelab.lan";
      };
    };
  };

  fileSystems."/nfs" = {
    device = "192.168.29.1:/share";
    fsType = "nfs";
    options = ["x-systemd.automount" "noauto" "nfsvers=4.2" "proto=rdma" "port=20049" "sec=krb5p"];
  };
}
