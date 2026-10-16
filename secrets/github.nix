# nix 的 GitHub access token（sops 加密），给 `nix.conf` 用，避免拉私有/限流的 flake 时被限速。
#
# 以前这里靠 `config.networking.hostName == "zed" || "dot" || "homelab"` 判断，
# 结果是"加一台要用 token 的机器，得回来改这个和它无关的文件"。
# 现在改成开关：在 host 里写一行
#     services.pharra.nix-access-token.enable = true;
# 即可，这个文件不用再动。
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.pharra.nix-access-token;
in {
  options.services.pharra.nix-access-token = {
    enable = mkEnableOption "nix 的 GitHub access token（解密并 include 进 nix.conf）";
  };

  config = mkIf cfg.enable {
    nix.extraOptions = ''
      experimental-features = nix-command flakes
      !include ${config.sops.secrets.nixAccessTokens.path}
    '';

    sops.secrets.nixAccessTokens = {
      mode = "0440";
      group = config.users.groups.keys.name;
      sopsFile = ./github.yaml;
    };
  };
}
