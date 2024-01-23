{
  config,
  pkgs,
  interface,
  ...
}: {
  services = {
    # samba = {
    #   enable = true;
    #   package = pkgs.sambaFull;
    #   extraConfig = ''
    #     workgroup = WORKGROUP
    #     server string = homelab
    #     netbios name = homelab
    #     security = user
    #     #use sendfile = yes
    #     #max protocol = smb2
    #     # note: localhost is the ipv6 localhost ::1
    #   '';
    #   shares = {
    #     public = {
    #       path = "/smb/public";
    #       browseable = "yes";
    #       "read only" = "no";
    #       "guest ok" = "yes";
    #       "create mask" = "0644";
    #       "directory mask" = "0755";
    #       "force user" = "wf";
    #       "force group" = "users";
    #     };
    #   };
    # };
    samba-wsdd = {
      enable = true;
      extraOptions = ["--ipv4only"];
      #hostname = "ksmbd";
    };
  };

  environment = {
    systemPackages = with pkgs; [
      ksmbd-tools
    ];
  };

  systemd.services.ksmbd = {
    enable = true;
    description = "ksmbd userspace daemon";
    wants = ["network-online.target"];
    after = ["network-online.target" "network.target"];
    serviceConfig = {
      Type = "forking";
      PIDFile = "/run/ksmbd.lock";
      ExecStart = "${pkgs.ksmbd-tools}/bin/ksmbd.mountd -C /etc/ksmbd/ksmbd.conf -P /etc/ksmbd/ksmbdpwd.db";
      ExecReload = "${pkgs.ksmbd-tools}/bin/ksmbd.control --reload";
      ExecStop = "${pkgs.ksmbd-tools}/bin/ksmbd.control --shutdown";
    };
    wantedBy = ["multi-user.target"];
  };
  boot.kernelModules = ["ksmbd"];
  environment.etc."ksmbd/ksmbd.conf" = {
    text = ''
        [global]
      	; global section parameters
      	bind interfaces only = yes
      	guest account = nobody
      	interfaces = ${interface.ib} ${interface.eth} br0 ${interface.intern}
      	netbios name = ksmbd
      	server max protocol = SMB3_11
      	server min protocol = SMB3_11
      	server multi channel support = yes
      	server string = ksmbd
      	tcp port = 445
      	workgroup = WORKGROUP

      [share]
      	path = /share
        read only = no
        force user = sftp
        force group = sftp

      [nix-persistent]
      	path = /nix/persistent
        read only = no
        force user = wf
        force group = wf
    '';
  };

  fileSystems."/nfs" = {
    device = "tmpfs";
    options = ["bind"];
  };

  fileSystems."/nfs/persistent" = {
    device = "/nix/persistent";
    options = ["bind"];
  };

  fileSystems."/nfs/share" = {
    device = "/share";
    options = ["bind"];
  };

  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /nfs         192.168.0.0/16(rw,fsid=0,no_subtree_check)

    /nfs/persistent  192.168.0.0/16(rw,nohide,insecure,no_subtree_check)
    /nfs/share  192.168.0.0/16(rw,nohide,insecure,no_subtree_check)
  '';
}
