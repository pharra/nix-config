self: super: {
  linux_mlx = super.linux_mlx.extend  (lpself: lpsuper: {
    evdi = super.linux_mlx.evdi.overrideAttrs (oldAttrs: {
      version = "unstable-2024-01-08";
      src = super.fetchFromGitHub {
        owner = "DisplayLink";
        repo = "evdi";
        rev = "0313ecac7aa3990c6f9a0d0f258c87e20e116bdd";
        hash = "sha256-OebHunR67QUrh8GKTuxb8WI6+/M/y/nVhQME+1An3JA=";
      };
      meta.broken = lpsuper.kernel.kernelOlder "4.19";
    });
  });
}
