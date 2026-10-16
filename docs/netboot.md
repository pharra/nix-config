# zed 的网络启动（netboot）链路

zed 这台机器除了本地启动，还有"从网络盘启动"的两条路径。这是本仓库最难一眼看懂的部分，
因为它横跨 `hosts/`、`lib/`、`modules/boot/` 三层，而且宿主和 guest 的配置写在不同文件里。

## 两条路径

| | 路径 A：zed 自己走网络启动 | 路径 B：在 homelab 上跑一个 zed guest |
| --- | --- | --- |
| 配置名 | `zed_net_{kde,gnome,cosmic,wm}`（和 `zed_*` 并列，是 24 个配置里的 4 个） | 不是独立配置：它是 homelab 配置求值过程中生成的一个 NixOS system |
| 怎么组装 | `hosts/registry.nix` 的 `zed_net` 条目：`[./zed, netboot.nvmfRoot {iscsi = netboot.iscsiBoot;}, netboot.efiFromIscsi]` | `hosts/homelab/default.nix` 里 `zedGuestSystem = mkZedGuest {inherit nixpkgs home-manager;}` |
| 生成器 | `lib/netboot.nix` 的覆盖片段（NVMF root / iSCSI EFI） | `lib/mkZedGuest.nix`（NFS root + NVMF root 的 zed guest 系统） |
| 现状 | **活的**：CI 里会编译 `zed_net_wm.config.system.build.toplevel` | **目前没在服务**：homelab 上 `services.pharra.ipxe-host.nfs.enable = false`，见下 |

两条路径共用 `lib/netboot.nix` 里的同一份覆盖片段（NVMF RDMA 地址/端口/target、iSCSI 引导参数、
zfs pool 名、`/boot/efi` 的来源），所以改地址只需要改那一个文件。

## 宿主侧（homelab 需要提供什么）

| 文件 | 负责 |
| --- | --- |
| `hosts/homelab/default.nix` 的 `services.pharra.ipxe-host` | iPXE 引导入口：`iscsi.items` 里按 MAC 匹配 guest（`9c:52:f8:8e:dd:d8` / `58:47:ca:79:85:1c`），指向 iSCSI target `iqn.2016-06.io.spdk:zednetefi` |
| `modules/boot/ipxe-host/` | 真正的实现：`ipxe-server.nix` 起静态 web 服务（`:8080`）并生成 iPXE 菜单/引导段、防火墙端口；`guest-datasets.nix` 负责 NFS guest 的 ZFS 数据集与导出；`guests.nix` 算每个 guest 的内核/initrd 路径 |
| `modules/storage/spdk-container/` | 提供 NVMF / iSCSI target（容器里的 `spdk_tgt`，配置文件默认 `/home/<user>/spdk/rdma_config.json`，可用 `configFile` 选项改） |
| `modules/network/dhcp-server/` | 给 guest 发地址（`services.pharra.dhcp-server`，网段与静态主机在 `hosts/homelab/default.nix` 里） |

## guest 侧（zed 需要什么）

| 文件 / 选项 | 负责 |
| --- | --- |
| `modules/boot/boot-over-nvmf/`（`services.nvmf-root.*`） | guest 侧的根文件系统编排：NVMF(RDMA) root + iSCSI 引导，含 initrd 网络骨架 |
| `modules/boot/boot-over-nfs/`（`services.nfs-root.*`） | 同上但走 NFS root（当前只有路径 B 会用） |
| `modules/boot/netboot-root-common.nix` | 上面两个模块共用的 initrd 网络骨架（选项、wait-online、networkd 接管、等对端可达的 oneshot） |
| `modules/boot/nvmf/`（`boot.nvmf.*`） | NVMF initiator 的内核/工具层（`multiAddress` / `address` / `port` / `target`） |
| `modules/boot/iscsi-root/`（`boot.iscsi-root.*`） | 从 iSCSI 根盘启动的 initrd 支持；**注意**它是 nixpkgs `root-initiator.nix` 的本地副本，选项路径故意不叫 `boot.iscsi-initiator`（nixpkgs 自己声明了它，同名会撞车） |

## 想改某样东西，改哪个文件

| 想改 | 改这里 |
| --- | --- |
| guest 的 MAC、iSCSI target 名 | `hosts/homelab/default.nix` 的 `services.pharra.ipxe-host.iscsi.items` |
| NVMF 的地址 / 端口 / target、zfs pool 名、`/boot/efi` 来源 | `lib/netboot.nix`（两条路径共用） |
| guest 系统的模块组成（哪个 build 变体、带哪些覆盖） | `lib/mkZedGuest.nix`（路径 B）／`hosts/registry.nix` 的 `zed_net` 条目（路径 A） |
| iPXE 菜单长什么样、引导段怎么写 | `modules/boot/ipxe-host/ipxe-server.nix` |
| 给 guest 发地址的网段 | `hosts/homelab/default.nix` 的 `services.pharra.dhcp-server.networks` |

## 两个容易踩的点

1. **路径 B 现在是"准备了但没启用"**：`hosts/homelab/default.nix` 里写着
   `nfs.guests.zed.system = zedGuestSystem`，但同一个块里 `nfs.enable = false`。
   由于 Nix 是惰性的，`zedGuestSystem` 在当前 homelab 配置里**根本不会被求值**
   —— 也就是说改了 `lib/mkZedGuest.nix` 却看不出任何变化是正常的。
   要让这条路径生效：把 `nfs.enable` 打开（并把 guest 的 MAC 填进 `guests.zed.macs`），
   之后 iPXE 菜单里才会出现 NFS 引导项、`ipxe/zed/{bzImage,initrd}` 资产才会生成。
2. **改这条链之后，务必至少做一次强制求值**（`nix eval` 单个配置的 toplevel drvPath），
   而不要只看 `attrNames` —— 惰性求值下，很多错误（比如模块里变量没绑定）
   只有在真正算 drv 的时候才会暴露。
