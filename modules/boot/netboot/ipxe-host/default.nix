# ipxe-host：给网络启动的 guest 提供 iPXE 引导资产与 NFS 根。
# 实现拆到同目录两个子模块（共用同一个 services.pharra.ipxe-host 命名空间）：
#   guest-datasets.nix —— NFS guest 的 ZFS 数据集、挂载点、NFS 导出
#   ipxe-server.nix    —— iPXE 资产的静态 web 服务、菜单模板、防火墙端口
# 两者共用的 guest 引导信息在 guests.nix。
{lib, ...}:
with lib; {
  imports = [
    ./guest-datasets.nix
    ./ipxe-server.nix
  ];

  options = {
    services.pharra.ipxe-host = {
      enable = mkEnableOption "Unified iPXE host for NFS and iSCSI boot";

      nfs = {
        enable = mkEnableOption "NFS boot support";

        zfsPool = mkOption {
          type = types.str;
          default = "system";
          description = "ZFS pool name for storing guest data.";
        };

        guests = mkOption {
          type = types.attrsOf (types.submodule {
            options = {
              system = mkOption {
                type = types.unspecified;
                description = "The guest NixOS system configuration (built system).";
              };
              macs = mkOption {
                type = types.listOf types.str;
                default = [];
                description = "MAC addresses that should auto-boot this guest (e.g. 52:54:00:12:34:56).";
              };
            };
          });
          default = {};
          description = "Guest systems to serve via iPXE and NFS.";
        };
      };

      iscsi = {
        enable = mkEnableOption "iSCSI boot support";

        items = mkOption {
          type = types.listOf (types.submodule {
            options = {
              macs = mkOption {
                type = types.listOf types.str;
                default = [];
                description = "MAC addresses that should auto-boot this iSCSI target.";
              };

              name = mkOption {
                type = types.str;
                description = "Name of this iSCSI boot item.";
              };

              iscsi-target = mkOption {
                type = types.str;
                description = "iSCSI target NQN.";
              };
            };
          });
          default = [];
          description = "iSCSI boot items to expose via iPXE menu.";
        };
      };
    };
  };
}
