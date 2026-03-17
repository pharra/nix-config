{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.udev-symlink;
  mkRule = rule: let
    pciPath = rule.pciPath;
    symlinkName = rule.symlinkName;
  in
    concatStringsSep "\n" [
      ''KERNEL=="card*", KERNELS=="${pciPath}", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/${symlinkName}-card"''
      ''KERNEL=="renderD*", KERNELS=="${pciPath}", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/${symlinkName}-render"''
    ];
  mkAllRules = rules: concatMapStringsSep "\n\n" mkRule rules;
in {
  options.services.udev-symlink = {
    enable = mkEnableOption "udev symlink";

    rules = mkOption {
      type = types.listOf (
        types.submodule {
          options.pciPath = mkOption {
            type = types.str;
            description = "PCI 总线路径，例如 0000:01:00.0";
          };
          options.symlinkName = mkOption {
            type = types.str;
            description = "生成 symlink 名称的前缀，例如 gpu0";
          };
        }
      );
      default = [];
      description = "PCI 设备到 dri symlink 名称映射列表";
    };
  };

  config = mkIf cfg.enable {
    boot.initrd.services.udev.rules = mkAllRules cfg.rules;
    services.udev.extraRules = mkAllRules cfg.rules;
  };
}
