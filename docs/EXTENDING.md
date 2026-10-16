# 扩展指南

这份文档只回答一件事：**加东西要改哪些文件**。每条都标了「必改 / 按需」，以及为什么可以这么少。

> 这套结构的设计目标：加一台机器只改 3 个文件（都在 `hosts/` 里），加一个自建模块只改 1 个新文件 + 1 行开关。

## 一、加一台机器

### 必改 3 个文件

| 文件 | 写什么 |
| --- | --- |
| `hosts/<name>/hardware-configuration.nix` | `nixos-generate-config` 生成的，不要手改 |
| `hosts/<name>/default.nix` | 这台机器的「自我介绍」：`networking.hostName`、`system.stateVersion`、`services.pharra.*` 开关、磁盘/网卡/显卡等宿主特有设置 |
| `hosts/registry.nix` | 加一条记录：`name` / `builds` / `system` / `nixos-modules`，可选 `hostname`（部署地址）与 `specialArgs` |

验证（只求值不构建，几十秒）：

```bash
nix eval --raw .#nixosConfigurations.<name>_<build>.config.system.build.toplevel.drvPath
```

**为什么只要这 3 个**：`hosts/registry.nix` 是纯数据，构建逻辑在 `lib/default.nix`；
bootloader / NetworkManager / libvirt / 用户组这些以前每台机器都抄一遍的设置已经在
`modules/core/common`（`services.pharra.common.enable`）里；桌面栈在 `services.pharra.desktop`；
build 变体复用 `lib/variants.nix` 里已有的那 6 个。想知道某个设置是谁设的，按
`hosts/<name>` → `core/common` → `core/desktop` → `lib/variants.nix` 这个顺序找。

### 按需改动（不写不会报错，只在用到时才发现）

| 需求 | 要改哪里 |
| --- | --- |
| 解密 sops 秘密 | `.sops.yaml` 的 `creation_rules` 里加这台机器的 age key（`ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub`） |
| 解密 agenix 秘密 | `secrets/agenix/secrets.nix` 里加它的 ssh host key，并把要用的秘密 `publicKeys` 带上它 |
| 用 nix 的 GitHub token | 只在自己的 host 文件里加一行 `services.pharra.nix-access-token.enable = true;` |
| 让 CI 真正编译它 | 改 `.github/workflows/nixos.yml` 里 `build` 任务的矩阵（目前是硬写的 4 项） |
| 网络启动（像 zed_net） | 见 [`netboot.md`](netboot.md)（宿主侧 homelab、guest 侧 zed 的完整链路） |

### 加完机器后建议做的两件事

```bash
nix fmt .                                  # 格式化
nix eval .#nixosConfigurations --apply 'x: builtins.attrNames x'   # 确认新配置出现在列表里
```

## 二、加一个自建模块

1. `cp -r modules/_template modules/<域>/<名字>`，把骨架里的 `my-module` 换成你的选项名。
2. 在需要的 host 里加一行：`services.pharra.<名字>.enable = true;`
   （Home Manager 模块则放在 `home-modules/<名字>/`，在 `lib/variants.nix` 的 `homeSwitch` 表里按 build 变体打开。）

**没有注册表要登记**：`lib/importModules.nix` 自动发现 `modules/<域>/<名字>/default.nix`
（以 `_` 开头的目录会被跳过，所以 `_template` 本身不会被加载）。

四条容易踩的约定（骨架注释里也有）：

- 域只有 4 个：`services.pharra.*`（自有服务，默认放这里）/ `hardware.*` / `boot.*` / `virtualisation.*`；
  目录名 = 选项路径的最后一段，统一 kebab-case
- 必须有 `enable` 开关（`mkEnableOption`），默认关闭
- 不要在模块里硬编码宿主信息：用户名用 `specialArgs` 里的 `username`，网段/掩码/路径做成模块选项
- 脚本/模板正文超过 ~30 行就放同目录独立 `.nix` 文件。
  **不要**用 `builtins.readFile` 抽成 `.sh` —— 那些正文里有 `${pkgs...}` 插值，抽成 `.sh` 会变成字面量

## 三、加一个上游（GitHub）flake 模块

先判断一件事：**这个模块是不是所有机器都要有它的选项？** 是走 A，否走 B。

### A. 全局基础设施（sops-nix / agenix / impermanence / NixVirt 这类）

1. `flake.nix` 的 `inputs` 加一条（记得 `inputs.nixpkgs.follows = "nixpkgs";`）
2. `lib/default.nix` 的 `common-nixos-modules` 列表里加 `inputs.<名字>.nixosModules.default`，
   **并写一句注释说明为什么必须全局**
3. 更新锁：`nix flake lock`（或 `nix flake update <名字>`）

### B. 按需功能（只给某些机器用）

不要进全局列表，在 host 里直接 import：

```nix
# hosts/<name>/default.nix
{inputs, ...}: {
  imports = [inputs.<名字>.nixosModules.default];

  services.<名字>.enable = true;
}
```

`specialArgs` 里已经有 `inputs`（见 `lib/default.nix` 的 `commonSpecialArgs`），所以 host 模块能直接拿到。

### 为什么不能什么都往全局塞

`common-nixos-modules` 是全有或全无的：塞进去的模块会在 24 个配置里全部求值。
踩过的坑：`boot.iscsi-initiator` 这个选项名与 nixpkgs 自带的 `root-initiator.nix` 撞车，
eval 直接报 "already declared"（本地副本只好改叫 `boot.iscsi-root`，注释在
`modules/boot/iscsi-root/default.nix` 里）。

**加之前先确认它的选项路径与 nixpkgs 不冲突**，并且考虑清楚"是不是每台机器都要加载它"。

## 四、加一个秘密

见 [`../secrets/README.md`](../secrets/README.md)：sops-nix 与 agenix 两套并存的原因、
各自的加解密流程、以及"哪些秘密现在没人用"都写在那里。

## 五、加一个容器服务

`services/<名字>/default.nix`（自动导入），公共的 podman 运行时写一行：

```nix
imports = [../podman-runtime.nix];
```

注意这些文件是 compose2nix 生成物，所以只做「抽公共块 + imports」，不要大改结构
（理由见 README 的「设计取舍」）。
