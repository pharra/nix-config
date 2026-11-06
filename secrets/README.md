# Secrets 管理

本仓库统一使用 **sops-nix**，密文都在仓库内：

| 用途     | 密文位置                                                              | CLI    |
| -------- | --------------------------------------------------------------------- | ------ |
| 主力方案 | `secrets/*`、`services/<name>/<name>.env\|json`、各配置目录里的整文件秘密 | `sops` |

原则不变：传输过程与 `/nix/store` 里都是密文，只在最终落地时解密。

## sops-nix

- 加密对象与 recipient 定义在根目录 `.sops.yaml`
- 编辑：`sops secrets/default.yaml`（私钥可用 `SOPS_AGE_KEY_FILE` 指定）
- NixOS 侧用法：`sops.secrets."<name>" = { sopsFile = ./xxx.yaml; format = "dotenv"; };`，
  再引用 `config.sops.secrets."<name>".path`；需要模板替换时用 `config.sops.placeholder."<name>"`
  - 例子：`services/reader/default.nix`（dotenv 作为容器 environmentFiles）
  - 例子：`services/caddy/default.nix`（用 placeholder 渲染出 Caddyfile）
- 解密身份：`secrets/nixos.nix` 里 `sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"]`

## 整文件秘密

整文件秘密直接放在使用它的配置目录旁，不集中在 `secrets/` 下：

| 秘密 | 文件 | 格式 |
| --- | --- | --- |
| `caddy_server_conf` | `hosts/azure/server/caddy_server_conf` | `binary` |
| `xray_server_conf` | `hosts/azure/server/xray_server_conf.json` | `json` + `key = ""`（整个 JSON） |
| `restic_password` | `modules/storage/backup/restic_password` | `binary` |
| `rclone_config` | `hosts/homelab/rclone_config.ini` | `ini` + `key = ""`（暂未声明） |

caddy/xray 部署在 azure，`.sops.yaml` 给这两个文件额外加了 azure 的 age key；
azure 侧通过 `sops.age.sshKeyPaths` 使用 `/home/wf/.ssh/id_ed25519` 解密。

## 当前没有被任何模块引用的秘密

- `hosts/homelab/rclone_config.ini`（`hosts/homelab/storage.nix` 里的 rclone 同步代码是注释状态；
  要恢复时先在那里声明 `sops.secrets.rclone_config`）

## 注意事项

- 不要提交明文；也不要把秘密放到外部私有仓库再当 flake input 引用（上游模板的旧做法，本仓库已改为全部 in-tree）
- 改过 `.sops.yaml` 的 recipient 后要对已有文件跑 `sops updatekeys`，否则新机器解不开
- 每个秘密的 recipient 决定"哪些机器能解密"，改密钥前先确认目标机器的 age key 已在列
