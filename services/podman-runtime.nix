# 所有 compose2nix 生成的服务共用的 podman 运行时配置。
#
# services/<name>/default.nix 是 compose2nix 生成的，逐个手工删改会在下次重新生成时丢失，
# 所以公共部分集中在这里，由各服务模块 imports 引入；各服务文件里只保留容器定义本身。
{config, ...}: {
  # Runtime
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
  };

  # Enable container name DNS for all Podman networks.
  networking.firewall.interfaces = let
    matchAll =
      if !config.networking.nftables.enable
      then "podman+"
      else "podman*";
  in {
    "${matchAll}".allowedUDPPorts = [53];
  };

  virtualisation.oci-containers.backend = "podman";
}
