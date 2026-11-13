{
  config,
  lib,
  username,
  ...
}:
with lib; let
  cfg = config.services.pharra.preservation;
in {
  options = {
    services.pharra.preservation = {
      enable = mkEnableOption "preservation-based state management on a tmpfs root";
    };
  };

  config = mkIf cfg.enable {
    preservation = {
      enable = true;

      preserveAt."/nix/persistent" = {
        # 对应 impermanence 的 hideMounts：bind mount 不出现在文件管理器里
        commonMountOptions = ["x-gvfs-hide"];

        directories = [
          "/var/backup"
          "/var/cache"
          "/var/lib"
          "/var/log"
          "/etc/NetworkManager/system-connections"
          "/etc/ksmbd"
          "/etc/caddy"
          "/etc/v2raya"
          "/etc/cdi"
          #"/smb"

          {
            directory = "/home/${username}";
            user = "${username}";
            group = "${username}";
            # 等价于 impermanence 时期的 chmod u=rwx,g=r,o=；tmpfiles 只认八进制
            mode = "0740";
          }
        ];

        files = [
          # 机器 ID 在 sysinit 阶段 bind mount（和原来的 impermanence 一致）。挂上之后
          # systemd 的 commit 服务会失败，所以直接关掉它（见下面的 suppressedSystemUnits）。
          {
            file = "/etc/machine-id";
            inInitrd = true;
          }

          # 私钥必须用 symlink：bind mount 的 tmpfiles 规则会把模式改成默认的 0644，
          # 持久卷上的 0600 被改掉之后 sshd 会拒绝使用这对 host key。
          #
          # inInitrd 是必须的：NixOS 的 stage-2 activation 现在跑在 initrd 里
          # （initrd-nixos-activation.service → chroot /sysroot prepare-root），而 sops
          # 的 age 身份就是这把 host key。impermanence 时期靠 persist-files 这个
          # activation 片段（按名字排序在 setupSecrets 之前）先把 key bind mount 上；
          # preservation 不用 activation，若不放进 initrd，activation 时 key 还不存在，
          # sops 会现生成一把新 key 然后解密失败（所有 sops 模板/秘密全空 → mihomo 起不来）。
          {
            file = "/etc/ssh/ssh_host_ed25519_key";
            how = "symlink";
            configureParent = true;
            inInitrd = true;
          }
          {
            file = "/etc/ssh/ssh_host_rsa_key";
            how = "symlink";
            configureParent = true;
            inInitrd = true;
          }
          "/etc/ssh/ssh_host_ed25519_key.pub"
          "/etc/ssh/ssh_host_rsa_key.pub"
          "/root/.zsh_history"
        ];
      };
    };

    # systemd-machine-id-commit.service would fail, but it is not relevant
    # in this specific setup for a persistent machine-id so we disable it
    #
    # see the firstboot example below for an alternative approach
    systemd.suppressedSystemUnits = ["systemd-machine-id-commit.service"];

    # age.identityPaths = ["/nix/persistent/etc/ssh/ssh_host_ed25519_key"];

    fileSystems."/" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = ["relatime" "mode=755" "nosuid" "nodev"];
    };
  };
}
