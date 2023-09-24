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
      ExecStart = "${pkgs.ksmbd-tools}/bin/ksmbd.mountd -c /etc/ksmbd/ksmbd.conf -u /etc/ksmbd/ksmbdpwd.db";
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
      	interfaces = ${interface.ib} ${interface.eth}
      	netbios name = ksmbd
      	server max protocol = SMB3_11
      	server min protocol = SMB2_10
      	server multi channel support = yes
      	server string = ksmbd
      	tcp port = 445
      	workgroup = WORKGROUP

      [share]
      	path = /share
        read only = no
        force user = wf
        force group = wf
    '';
  };
}
