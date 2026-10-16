# 一组杂项脚本（GPU 直通、fluent disk、显示器 EDID）。
# 脚本正文在 gpu.nix / fluent.nix / monitor.nix 里（保持字符串字面量，Nix 插值语义不变），
# 这里只做"定义成命令 + 装进 systemPackages"。
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.pharra.scripts;

  gpu = import ./gpu.nix {inherit pkgs;};
  fluent = import ./fluent.nix {inherit pkgs;};
  monitor = import ./monitor.nix {inherit pkgs;};

  attach_gpu = pkgs.writeShellScriptBin "attach_gpu" gpu.attach;
  detach_gpu = pkgs.writeShellScriptBin "detach_gpu" gpu.detach;

  init-fluent-disk = pkgs.writeShellScriptBin "init-fluent-disk" fluent.init;
  mount-fluent = pkgs.writeShellScriptBin "mount-fluent" fluent.mount;
  umount-fluent = pkgs.writeShellScriptBin "umount-fluent" fluent.umount;

  add_monitor = pkgs.writeShellScriptBin "add_monitor" monitor.add;
  remove_monitor = pkgs.writeShellScriptBin "remove_monitor" monitor.remove;
in {
  options = {
    services.pharra.scripts = {
      enable = mkEnableOption "custom scripts";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      init-fluent-disk
      mount-fluent
      umount-fluent
      add_monitor
      remove_monitor

      attach_gpu
      detach_gpu

      spdk-python
    ];
  };
}
