# 网络启动宿主侧：生成给 zed 用的 guest 系统，并用 iPXE + NFS 把它引导起来。
# 完整链路见 modules/boot/netboot/README.md（注意当前 services.pharra.ipxe-host.nfs.enable = false）。
{
  lib,
  nixpkgs,
  mkZedGuest,
  ...
}:
with lib; let
  zedGuestSystem = mkZedGuest {inherit nixpkgs;};
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

  # 注意：NFS 的导出（exports）不在这里 —— 它由 ZFS 数据集上的 sharenfs 属性提供（手工设置，不在 Nix 里），
  # 所以这里只需要把服务打开。改导出请用 zfs set sharenfs=... 。
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
