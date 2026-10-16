# zed 从网络盘启动（NVMF/iSCSI + NFS）的公共覆盖片段。
# 两处共用：hosts/registry.nix 的 zed_net 配置、lib/mkZedGuest.nix（homelab 上跑的 zed guest）。
{lib}: {
  # zed_net 用 iSCSI 引导 EFI
  iscsiBoot = {
    enable = true;
    initiatorName = "iqn.2020-08.org.linux-iscsi.initiatorhost:zed_net";
    discoveryAddress = "192.168.29.1";
    targetName = "iqn.2016-06.io.spdk:zednetefi";
  };

  # NVMF(RDMA) root + 对应的 zfs pool 名
  nvmfRoot = {iscsi ? {enable = false;}}: {
    services.zfs-config.poolName = lib.mkForce "zed_net";

    services.nvmf-root = {
      enable = true;
      interface = ["mlx5_0"];
      nvmf = {
        enable = true;
        transport = "rdma";
        target = "nqn.2016-06.io.spdk:zed_net";
        address = "192.168.29.1";
        port = 4420;
      };
      inherit iscsi;
      network = {
        dhcp = "ipv4";
      };
    };
  };

  # NFS root（只有 homelab 上的 zed guest 用）
  nfsRoot = {
    services.nfs-root = {
      enable = true;
      interface = ["mlx5_0"];
      nfs = {
        rootPath = "/system/zed/nix";
        transport = "rdma";
        multipathPeers = [
          {
            clientIp = "192.168.29.2";
            serverIp = "192.168.29.1";
          }
          # {
          #   clientIp = "192.168.254.2";
          #   serverIp = "192.168.254.5";
          # }
        ];
      };
    };
  };

  # netboot 场景下没有本地 ESP
  efiFromIscsi = {fileSystems."/boot/efi".device = lib.mkForce "/dev/disk/by-label/zednetefi";};
  disableEfi = {fileSystems."/boot/efi".enable = lib.mkForce false;};
}
