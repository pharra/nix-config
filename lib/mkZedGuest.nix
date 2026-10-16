# 在 homelab 上运行的 zed 网络启动 guest 系统（NFS + NVMF root）。
# 调用签名保持 host 侧原样：mkZedGuest {inherit nixpkgs home-manager;}
{
  nixosSystem,
  common-nixos-modules,
  commonSpecialArgs,
  variants,
  username,
}: {
  nixpkgs,
  home-manager,
  ...
}:
nixosSystem {
  inherit nixpkgs home-manager;
  system = "x86_64-linux";
  specialArgs = commonSpecialArgs;
  nixos-modules =
    [../hosts/zed]
    ++ common-nixos-modules
    ++ [
      (variants.nixosModule "kde")
      {
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
          iscsi = {
            enable = false;
          };
          network = {
            dhcp = "ipv4";
          };
        };

        services.zfs-config.poolName = nixpkgs.lib.mkForce "zed_net";

        fileSystems."/boot/efi".enable = nixpkgs.lib.mkForce false;
      }
    ];
  home-module = variants.mkHomeModule username "kde";
}
