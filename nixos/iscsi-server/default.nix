{
  lib,
  pkgs,
  config,
  libs,
  ...
}: {
  # services.target = {
  #   enable = true;
  #   config = builtins.fromJSON (builtins.readFile ./saveconfig.json);
  # };

  #   environment = {
  #     systemPackages = with pkgs; [
  #       tgt
  #     ];
  #   };
  #   systemd.packages = [pkgs.tgt];

  #   environment.etc."tgt/targets.conf" = {
  #     text = ''
  # default-driver iscsi
  # <target iqn.2006-06.org.spdk:data>
  # 	backing-store /dev/nbd2
  # 	initiator-name 192.168.0.0/16
  #   allow-in-use yes
  # </target>

  #     '';
  #   };

  # environment = {
  #   systemPackages = with pkgs; [
  #     mono
  #   ];
  # };
}
