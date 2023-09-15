self: super: {
  qemu = super.qemu.overrideAttrs (oldAttrs: rec {
    patches =
      oldAttrs.patches
      ++ [
        ./qemu-vfio-user.patch
      ];

    configureFlags = ["--enable-multiprocess"] ++ oldAttrs.configureFlags;
  });
}
