# nix-config

pharra 的 NixOS 配置：一个 flake 管多台机器 × 多个桌面变体。

配置名统一是 `<host>_<build>`，例如 `zed_wm`、`homelab_base`、`zed_net_kde`。共 24 个组合。

## 配置矩阵

| host | 机器 | builds |
| --- | --- | --- |
| `azure` / `azure_arm` | Azure 虚拟机（x86_64 / aarch64） | `base` |
| `dot` | Surface Book 2 | `kde` `gnome` `cosmic` `wm` |
| `gs65` | MSI GF65（hostname 是 `nix65`） | `kde` `gnome` `cosmic` `wm` |
| `zed` | 主力机：i5-13600KF + RTX 4090 | `kde` `gnome` `cosmic` `wm` `denial` |
| `zed_net` | 同 zed，但从 NVMF/iSCSI 网络盘启动 | `kde` `gnome` `cosmic` `wm` |
| `homelab` | 服务器：ZFS + SPDK/NVMF + 一堆容器服务 | `base` `kde` `gnome` `cosmic` `wm` |

`build` 就是桌面环境组合，定义在 `lib/variants.nix`（`base`/`kde`/`gnome`/`cosmic`/`wm`/`denial`）。

## 目录结构

| 路径 | 作用 |
| --- | --- |
| `flake.nix` | 只放 inputs 与输出装配（`nixosConfigurations` / `apps` / `packages` / `formatter`） |
| `lib/` | 构建逻辑：`default.nix`（上下文装配）、`variants.nix`（build 变体表）、`importModules.nix`（模块自动发现）、`netboot.nix`、`mkZedGuest.nix`、`nixosSystem.nix` |
| `hosts/` | 每台机器一个目录（硬件、磁盘、网络、host 专属开关）；`hosts/registry.nix` 是 host 清单（纯数据） |
| `modules/` | 通用 NixOS 模块，分 7 个域，自动发现（见下） |
| `home-modules/` | Home Manager 模块（统一 `home.pharra.*` 命名空间），自动发现 |
| `services/` | 容器化服务（compose2nix 生成），由 `hosts/homelab` 导入；公共 podman 运行时在 `services/podman-runtime.nix` |
| `pkgs/` + `overlays/` + `overlay.nix` | 自定义包与 overlay |
| `secrets/` | 秘密（sops-nix + agenix），见 [`secrets/README.md`](secrets/README.md) |
| `nixos/` | 给 libvirt guest 复用的片段（`nixos/nixvirt/base.nix` 被 `hosts/*/nixvirt` 使用） |

`modules/` 的 7 个域：

| 域 | 内容 |
| --- | --- |
| `core/` | 全机与桌面基础：`common`、`desktop`、`no-desktop`、`user-group`、`impermanence`、`scripts`、`azure-tools` |
| `desktop/` | 桌面与外壳：`kde`、`gnome`、`cosmic`、`denial`、`desktop-shell`、`input-method`、`flatpak`、`audio-relay` |
| `hardware/` | 硬件驱动与固件：`mlx5`、`net-sriov`、`amd-gpu-edid-fix`、`mcontrolcenter`、`lianli-linux`、`surface-dtx-daemon`、`nvme-auto`、`udev-symlink` |
| `network/` | 网络与网络服务：`net-name`、`netns`、`docker-netns`、`network-bridge`、`dhcp-server`、`openwrt`、`tailscale`、`easytier`、`mihomo`、`samba`、`sftp-server`、`ddns-go` |
| `boot/` | 引导链：`nvmf`、`boot-over-nfs`、`boot-over-nvmf`、`iscsi-root`、`ipxe-host` |
| `vm/` | 虚拟化与客机：`libvirt`、`virtualisation`、`vfio`、`waydroid`、`archlinux` |
| `storage/` | 存储：`zfs-config`、`spdk-tgt`、`spdk-container` |

## 配置是怎么装配出来的

```
flake.nix                          只装配输出（nixosConfigurations / apps / packages / formatter）
  └─ lib/default.nix               上下文：common-nixos-modules、commonSpecialArgs、variants、secrets 路径
       ├─ hosts/registry.nix       host 清单（纯数据）：name / builds / system / nixos-modules
       ├─ lib/variants.nix         build 变体表：NixOS 侧开关 + home 侧开关 + 生成的 home 模块
       ├─ modules/<域>/<名字>/     自动发现，按 enable 开关生效
       ├─ home-modules/<名字>/     自动发现，统一 home.pharra.* 命名空间
       └─ secrets/                 sops-nix + agenix
  → 展开成 24 个 <host>_<build> 配置
```

每个配置由四层叠出来，找"某个设置是谁设的"就按这个顺序：

1. **宿主自己**：`hosts/<name>/default.nix`（网卡 MAC、磁盘、显卡、这台机器特有的开关）
2. **全机共用**：`modules/core/common`（`services.pharra.common.enable`，22 个配置里开着）
3. **桌面共用**：`modules/core/desktop`（`services.pharra.desktop.enable`）
4. **build 变体**：`lib/variants.nix`（kde / gnome / cosmic / wm / denial / base）

反过来：**要让所有机器都变，改第 2 层；要让所有桌面机都变，改第 3 层；只影响一台，改第 1 层。**
分层里底层用 `lib.mkDefault`、上层直接赋值，所以上层不需要 `mkForce` 就能覆盖（见「设计取舍」）。


## 模块的命名与组织规则

1. **只允许 4 个选项域**：
   - `services.pharra.*` —— 本仓库自有的机器级服务与开关（新模块默认放这里，不要再往裸 `services.*` 塞，避免与 nixpkgs 撞名）
   - `hardware.*` —— 硬件驱动/固件的启用
   - `boot.*` —— 引导链
   - `virtualisation.*` —— 虚拟化
   Home Manager 侧统一用 `home.pharra.*`。
2. **目录名 = 选项路径的最后一段**，统一 kebab-case。看目录就知道选项名：
   `modules/network/dhcp-server/` → `services.pharra.dhcp-server`。
3. **模块顺序只按模块名排序，与所在分组无关**（`lib/importModules.nix`）。
   这条不是洁癖：NixOS 的 list 型选项（`environment.systemPackages` 等）按模块顺序合并，
   顺序规则不稳定的话，"把模块换个分组"就会让一批配置的 drvPath 变化。现在换分组零影响。
4. **每个模块都要有 `enable` 开关**（`mkEnableOption`），且默认关闭；模块之间不要互相
   硬开对方的开关（例外见 `core/desktop`，它显式开启 `core/common` 等下层模块，属于刻意的分层组合）。
5. **分层用 `mkDefault`，不要用 `mkForce`**：底层模块给 `mkDefault` 默认值，上层直接赋值覆盖。
   `core/common` 给 en_US 的 `mkDefault`，`core/desktop` 直接写 zh_CN —— 结果与原来的 mkForce 相同，
   但不会有优先级打架。
6. 模块里不要硬编码宿主信息（用户名、家目录、网段、CPU 掩码）：用户名走 `specialArgs` 的 `username`，
   其余做成模块选项（例如 `network/tailscale.advertiseRoutes`、`storage/spdk-*.coreMask`）。

## zed 的网络启动（netboot）

zed 除了本地启动还有"从网络盘启动"的两条路径，横跨 `hosts/` `lib/` `modules/boot/` 三层，
是最难一眼看懂的部分 —— 专门的说明见 [docs/netboot.md](docs/netboot.md)。

## 常用命令

```bash
nix fmt                                        # alejandra 格式化（CI 会检查）

# 只求值不构建：确认某个配置没被改坏（几分钟内出结果）
nix eval --raw .#nixosConfigurations.zed_wm.config.system.build.toplevel.drvPath

# 本地构建 / 本机切换
nix build .#nixosConfigurations.zed_wm.config.system.build.toplevel
sudo nixos-rebuild switch --flake .#zed_wm

# 远程部署（nixinate），先 dry-run
nix run .#dot_wm-dry-run
nix run .#dot_wm

# 生成 Azure 镜像
nix build .#packages.x86_64-linux.azure-x64
```

`nix run .#<配置名>` 的可用名字 = 24 个配置名，外加对应的 `<配置名>-dry-run`。

## 加东西怎么加

> 逐步清单（必改 3 个文件 + 按需改动，以及为什么可以这么少）见 [docs/EXTENDING.md](docs/EXTENDING.md)。

- **新机器**：建 `hosts/<name>/hardware-configuration.nix` 与 `hosts/<name>/default.nix`，
  然后在 `hosts/registry.nix` 加一条（`name` / `builds` / `system` / `nixos-modules` / 可选 `hostname`、`specialArgs`）。
  **不需要改 `flake.nix`。**
- **新 build 变体**：在 `lib/variants.nix` 的 `nixos` 与 `homeSwitch` 两张表里各加一项，
  键必须一致（文件里有一句断言），加漏了或写错名字会在 eval 期直接报错。
- **新 NixOS 模块**：放到 `modules/<域>/<name>/default.nix` 即自动生效，不用登记注册表。
  要临时停用就写进 `lib/default.nix` 里 `importModules` 的 `disabled` 白名单（不要再注释掉注册行）。
- **新 Home Manager 模块**：放 `home-modules/<name>/default.nix`，在 `home.pharra` 下暴露 `enable` 开关。
- **新服务**：`services/<name>/default.nix`（自动导入），公共运行时写 `imports = [../podman-runtime.nix];`。
- **新秘密**：见 [`secrets/README.md`](secrets/README.md)。

## 设计取舍

- `home/` 原本有 6 个近乎逐字复制的 `<build>.nix`，现在统一由 `lib/variants.nix` 生成，
  `services.pharra.*`（NixOS 侧）与 `home.pharra.*`（home 侧）的开关写在同一条记录里。
- **`system.stateVersion` 刻意留在每个 host**：它代表该机器首次安装的版本，
  上提到公共模块会让新机器静默继承一个自己没声明过的值。
- `services/*/default.nix` 是 compose2nix 生成物：只把公共的 podman 运行时抽到
  `services/podman-runtime.nix`，其余保持原样，避免下次重新生成时冲突。
- `secrets/agenix` 用 `lib.cleanSourceWith` 只把 `*.age`/`*.env` 纳入 store：
  否则在那个目录里改一行文档，7 个用到 age 秘密的配置 drvPath 全变。
- 秘密有 sops-nix 与 agenix 两套：历史原因，未做迁移（迁移必须先解密，收益不大），新秘密优先用 sops。
- `boot/iscsi-root` 是 nixpkgs `root-initiator.nix` 的本地副本，选项路径故意不叫
  `boot.iscsi-initiator`（nixpkgs 自己声明了它，同名会撞车）。
- 大模块的拆分约定：脚本/模板正文放同目录的独立 `.nix` 文件（保持字符串字面量，Nix 插值才有效，
  所以不要用 `builtins.readFile` 抽成 `.sh`）；选项与实现分开（例如 `network/dhcp-server/` 的
  `options.nix` + `config.nix`，`core/common/` 的 `default.nix` 机器级 + `user.nix` 用户级）。
  这些子文件是普通 `.nix` 文件，不会被 `importModules` 当成模块自动导入。

## 休眠与未接线的模块

这些模块**保留在仓库里**（不要在清理时误删），但当前没有任何配置启用它们。
每个文件头部都有 `# 休眠模块：…` 注释说明原因：

| 模块 | 现状 |
| --- | --- |
| `hardware/amd-gpu-edid-fix` | 全仓库零引用（317 行） |
| `storage/spdk-tgt` | 零引用；homelab 用的是容器版 `storage/spdk-container` |
| `network/ddns-go` | 零引用 |
| `network/samba` | 零引用 |
| `network/tailscale` | 零引用（因此里面的 age 秘密也不会被解密） |
| `network/openwrt` | `hosts/homelab` 里显式 `enable = false` |
| `network/docker-netns` | 取值跟随 `openwrt.enable`，跟着一起关着 |
| `hardware/lianli-linux` | `hosts/zed/hardware-configuration.nix` 里显式 `enable = false` |
| `desktop/audio-relay` | `core/desktop` 里显式 `enable = false` |
| `home-modules/autostart` | 没有任何 home 配置启用 |

- `hardware/mlx4` 已删除（连同 `hosts/homelab/hardware-configuration.nix` 里那份从未生效的参数块）：
  它从来没被启用过。注意 `mlx4_0`/`mlx4_1` 是 homelab 上的**实际网卡名**，仍保留在 `hosts/homelab/default.nix`，与内核模块无关。

另外：

- `nixos/ipxe/`、`nixos/wireguard-server/`：没有被任何 host 启用
- `secrets/agenix/atticd.env`、`secrets/agenix/wireguard_homelab_private_key.age`：已注册但无模块引用
- `services/nfs-root`（`boot/boot-over-nfs`）在 24 个顶层配置里都是关的，但 homelab 上的 zed guest
  在用它（`lib/mkZedGuest.nix`），不是死代码

## CI

`.github/workflows/nixos.yml`：

- `eval`：全量 24 个配置求值（PR 阶段就能发现某个 host/build 组合被改坏）
- `format`：`nix fmt -- --check .`
- `lint`：statix + deadnix，目前仓库还有既存告警，故只报告不阻断
- `build`：4 个代表性配置真正编译（内核 / 服务器 / 桌面 / 网络启动各一），其余由 `eval` 兜底
