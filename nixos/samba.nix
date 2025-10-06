{
  config,
  pkgs,
  interface,
  ...
}: {
  services = {
    samba-wsdd = {
      enable = true;
      extraOptions = ["--ipv4only"];
      # openFirewall = true;
      #hostname = "ksmbd";
    };
  };

  environment = {
    systemPackages = with pkgs; [
      ksmbd-tools
    ];
  };

  # networking.firewall.allowedTCPPorts = [ 445 ];
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
      	interfaces = ${interface.eth} br0 ${interface.intern}
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
        force user = wf
        force group = users
    '';
  };

  services.nfs = {
    server = {
      enable = true;
      lockdPort = 4001;
      mountdPort = 4002;
      statdPort = 4000;
    };
    settings = {
      nfsd.udp = true;
      nfsd.rdma = true;
      # nfsd.vers2 = false;
      # nfsd.vers3 = false;
      # nfsd.vers4 = true;
      # nfsd."vers4.0" = false;
      # nfsd."vers4.1" = false;
      # nfsd."vers4.2" = true;
    };
  };
}
