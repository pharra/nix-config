# Secrets 管理

本仓库有两套秘密管理并存，**密文都在仓库内**（不再依赖外部私有仓库）：

| 系统 | 用途 | 密文位置 | CLI |
| --- | --- | --- | --- |
| **sops-nix** | 主力方案，新增秘密优先用它 | `secrets/*.yaml`、`services/<name>/<name>.env\|json` | `sops` |
| **agenix** | 历史遗留（tailscale / restic / rclone / caddy / xray 等） | `secrets/agenix/*.age` | `agenix` |

两者都是同一原则：传输过程与 `/nix/store` 里都是密文，只在最终落地时解密。

## 为什么有两套

agenix 是先用的方案。后来服务变多，`services/` 下 compose2nix 生成的 `*.env` / `*.json`
更适合用 sops（可以只改其中一个字段，而 agenix 是整文件加密）。
旧秘密没有迁移：迁移必须先解密（需要各机器的 age / ssh 私钥），收益不大，风险却更高。

## sops-nix（推荐）

- 加密对象与 recipient 定义在根目录 `.sops.yaml`（homelab / zed / dot 三个 age key）
- 编辑：`sops secrets/default.yaml`（私钥可用 `SOPS_AGE_KEY_FILE` 指定）
- NixOS 侧用法：`sops.secrets."<name>" = { sopsFile = ./xxx.yaml; format = "dotenv"; };`，
  再引用 `config.sops.secrets."<name>".path`；需要模板替换时用 `config.sops.placeholder."<name>"`
  - 例子：`services/reader/default.nix`（dotenv 作为容器 environmentFiles）
  - 例子：`services/caddy/default.nix`（用 placeholder 渲染出 Caddyfile）
- 解密身份：`secrets/nixos.nix` 里 `sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"]`

## agenix

- `secrets/agenix/*.age`：整个文件加密
- `secrets/agenix/secrets.nix` **只给 agenix CLI 用**，不参与 NixOS 求值，里面是各机器的 ssh host 公钥
- 新增/修改：`nix shell nixpkgs#agenix`，然后 `agenix -e secrets/agenix/xxx.age`
- NixOS 侧用法：模块里写 `age.secrets."xxx".file = "${mysecrets}/xxx.age";`，
  其中 `mysecrets = ./secrets/agenix`，由 `lib/default.nix` 通过 `specialArgs` 传给所有模块
- 解密身份：`secrets/agenix.nix` 的 `age.identityPaths`
  （有 impermanence 时用 `/nix/persistent/home/<user>/.ssh/id_ed25519`，否则用 `/home/<user>/.ssh/id_ed25519`）

## 当前没有被任何模块引用的秘密

- `secrets/agenix/atticd.env`
- `secrets/agenix/wireguard_homelab_private_key.age`（对应的 `nixos/wireguard-server` 模块也没有被任何 host 启用）

先保留不删：它们已在 `secrets.nix` 注册，删除容易和密钥轮换流程混淆；要清理就单独一个提交处理。

## 注意事项

- 不要提交明文；也不要把秘密放到外部私有仓库再当 flake input 引用（上游模板的旧做法，本仓库已改为全部 in-tree）
- 改过 `.sops.yaml` 的 recipient 后要对已有文件跑 `sops updatekeys`，否则新机器解不开
- 每个秘密的 recipient 决定"哪些机器能解密"，改密钥前先确认目标机器的 host key 已在列
