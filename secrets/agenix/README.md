# agenix secrets

存放 agenix 形式的整文件加密秘密（`*.age`；`atticd.env` 也是 age 密文，只是扩展名不同）。

- `secrets.nix` 只给 agenix CLI 用（声明每份密文可由哪些 ssh host 公钥解密），不参与 NixOS 求值。
- 新增/修改：`nix shell nixpkgs#agenix`，然后 `agenix -e secrets/agenix/xxx.age`。
- NixOS 侧通过 `mysecrets`（= `./secrets/agenix`）引用，见 `../README.md`。

## 这个目录里的非密文文件不会进 store

`lib/default.nix` 用 `lib.cleanSourceWith` 只保留 `*.age` / `*.env`，
所以在本目录里改文档（包括 `secrets.nix`）不会改变任何配置的 drvPath。

<!-- 文档改动漂移测试 -->
