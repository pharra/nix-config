self: super: {
  evdi = super.evdi.overrideAttrs (oldAttrs: rec {
    version = "unstable-2024-01-08";
    src = super.fetchFromGitHub {
      owner = "DisplayLink";
      repo = "evdi";
      rev = "0313ecac7aa3990c6f9a0d0f258c87e20e116bdd";
      hash = "sha256-OebHunR67QUrh8GKTuxb8WI6+/M/y/nVhQME+1An3JA=";
    };
    meta.broken = super.kernel.kernelOlder "4.19";
  });
}
