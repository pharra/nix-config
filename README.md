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
| `modules/` | 通用 NixOS 模块，目录自动发现 |
| `home-modules/` | Home Manager 模块（统一 `home.pharra.*` 命名空间），目录自动发现 |
| `services/` | 容器化服务（compose2nix 生成），由 `hosts/homelab` 导入；公共 podman 运行时在 `services/podman-runtime.nix` |
| `pkgs/` + `overlays/` + `overlay.nix` | 自定义包与 overlay |
| `secrets/` | 秘密（sops-nix + agenix），见 [`secrets/README.md`](secrets/README.md) |
| `nixos/` | 给 libvirt guest 复用的片段（`nixos/nixvirt/base.nix` 被 `hosts/*/nixvirt` 使用） |

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

- **新机器**：建 `hosts/<name>/hardware-configuration.nix` 与 `hosts/<name>/default.nix`，
  然后在 `hosts/registry.nix` 加一条（`name` / `builds` / `system` / `nixos-modules` / 可选 `hostname`、`specialArgs`）。
  **不需要改 `flake.nix`。**
- **新 build 变体**：在 `lib/variants.nix` 的 `nixos` 与 `homeSwitch` 两张表里各加一项，
  键必须一致（文件里有一句断言），加漏了或写错名字会在 eval 期直接报错。
- **新 NixOS 模块**：建 `modules/<name>/default.nix` 就自动生效，不用登记注册表。
  要临时停用就写进 `importModules` 的 `disabled` 白名单（不要再注释掉注册行）。
- **新 Home Manager 模块**：同上，放 `home-modules/<name>/default.nix`，在 `home.pharra` 下暴露 `enable` 开关。
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

## 尚未接线的遗留项

- `nixos/ipxe/`、`nixos/wireguard-server/`：没有被任何 host 启用
- `secrets/agenix/atticd.env`、`secrets/agenix/wireguard_homelab_private_key.age`：已注册但无模块引用

## CI

`.github/workflows/nixos.yml`：

- `eval`：全量 24 个配置求值（PR 阶段就能发现某个 host/build 组合被改坏）
- `format`：`nix fmt -- --check .`
- `lint`：statix + deadnix，目前仓库还有既存告警，故只报告不阻断
- `build`：4 个代表性配置真正编译（内核 / 服务器 / 桌面 / 网络启动各一），其余由 `eval` 兜底
