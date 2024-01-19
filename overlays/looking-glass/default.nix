self: super: {
  looking-glass-client = super.looking-glass-client.overrideAttrs (oldAttrs: rec {
    version = "c2237f29";
    src = super.fetchFromGitHub {
      owner = "gnif";
      repo = "LookingGlass";
      rev = "c2237f29ae891316b32a534e5d0dfec6616d6294";
      sha256 = "sha256-AOb79RiHpYnrPv/jHCijAgr4uIe+TUIsY8pmVt0b0cU=";
      fetchSubmodules = true;
    };
  });
}
