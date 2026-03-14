{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.udev-symlink;
  mkUdevRule = pciPath: symlinkName: ''
    KERNEL=="card*", \
    KERNELS=="${pciPath}", \
    SUBSYSTEM=="drm", \
    SUBSYSTEMS=="pci", \
    SYMLINK+="dri/${symlinkName}"
  '';
  mkAllRules = rules: concatStringsSep "\n" (map (rule: mkUdevRule rule.pciPath rule.symlinkName) rules);
in {
  options.services.udev-symlink = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "启用 udev symlink 规则自动生成";
    };
    rules = mkOption {
      type = types.listOf (types.attrsOf types.str);
      default = [];
      description = "PCI路径和symlink名称的数组，如 [{ pciPath = ...; symlinkName = ...; }]";
    };
  };

  config = mkIf cfg.enable {
    services.udev.extraRules = mkAllRules cfg.rules;
  };
}
