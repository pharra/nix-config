# 网络启动宿主侧：生成给 zed 用的 guest 系统，并用 iPXE + NFS 把它引导起来。
# 完整链路见 docs/netboot.md（注意当前 services.pharra.ipxe-host.nfs.enable = false）。
{
  config,
  lib,
  pkgs,
  nixpkgs,
  home-manager,
  mkZedGuest,
  ...
}:
with lib; let
  zedGuestSystem = mkZedGuest {inherit nixpkgs home-manager;};
in {
  # Enable iPXE host to serve zed guest system via NFS
  services.pharra.ipxe-host = {
    enable = true;
    nfs = {
      enable = false;
      guests.zed = {
        system = zedGuestSystem;
        # macs = ["9c:52:f8:8e:dd:d8" "58:47:ca:79:85:1c"];
      };
    };
    iscsi = {
      enable = true;
      items = [
        {
          macs = ["9c:52:f8:8e:dd:d8" "58:47:ca:79:85:1c"];
          name = "zed_net";
          iscsi-target = "iqn.2016-06.io.spdk:zednetefi";
        }
      ];
    };
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
    };
  };
}
