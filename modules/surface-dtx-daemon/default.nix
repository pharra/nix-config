{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
with lib; let
  cfg = config.services.surface-dtx-daemon;
  attach = pkgs.writeScript "attach.sh" "${cfg.attach}";
  detach = pkgs.writeScript "detach.sh" "${cfg.detach}";
  detach_abort = pkgs.writeScript "detach.sh" "${cfg.detach_abort}";
  configFile = pkgs.writeText "surface-dtx-daemon.conf" ''
    [log]
    level="info"

    [handler]
    attach="${attach}"
    detach="${detach}"
    detach_detach_abort="${detach_abort}"

    [delay]
    attach = 7
  '';
in {
  options = {
    services.surface-dtx-daemon = {
      enable = mkEnableOption "Surface DTX Daemon";
      attach = mkOption {
        type = types.str;
        default = ''
          #! /usr/bin/env bash
        '';
        description = ''
          Runs on clipboard attach
        '';
      };
      detach = mkOption {
        type = types.str;
        default = ''
          #! /usr/bin/env bash
          for usb_dev in /dev/disk/by-id/usb-*
            do
              dev=$(readlink -f $usb_dev)
              mount -l | grep -q "^$dev\s" && umount "$dev"
            done
        '';
        description = ''
          Runs on clipboard detach
        '';
      };
      detach_abort = mkOption {
        type = types.str;
        default = "${cfg.attach}";
        description = ''
          Runs on aborted clipboard detach
        '';
      };
    };
  };
  config = mkIf cfg.enable {
    systemd.services.surface-dtx-daemon = {
      wantedBy = ["multi-user.target"];
      path = [pkgs.surface-dtx-daemon pkgs.utillinux pkgs.bash];
      script = "RUST_BACKTRACE=full exec ${pkgs.surface-dtx-daemon}/bin/surface-dtx-daemon";
    };
    environment.systemPackages = [pkgs.surface-control];
    services.udev.packages = [pkgs.surface-dtx-daemon];
    services.dbus.packages = [pkgs.surface-dtx-daemon];
    systemd.packages = [pkgs.surface-dtx-daemon];
  };
}
