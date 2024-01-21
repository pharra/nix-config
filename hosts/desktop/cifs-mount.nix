{
  config,
  pkgs,
  username,
  ...
}: {
  # mount a smb/cifs share
  # services.rpcbind.enable = true; # needed for NFS
  # systemd.mounts = [
  #   {
  #     type = "nfs";
  #     mountConfig = {
  #       Options = "noatime";
  #     };
  #     what = "homelab.intern:/nfs/persistent";
  #     where = "/nix-persistent";
  #   }
  # ];

  # systemd.automounts = [
  #   {
  #     wantedBy = ["multi-user.target"];
  #     automountConfig = {
  #       TimeoutIdleSec = "600";
  #     };
  #     where = "/nix-persistent";
  #   }
  # ];
}
