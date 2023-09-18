self: super: {
  looking-glass-client = super.looking-glass-client.overrideAttrs (oldAttrs: rec {
    src = super.fetchFromGitHub {
      owner = "gnif";
      repo = "LookingGlass";
      rev = "e658c2e0a205c40701b00d97364c2a9903ed34cf";
      sha256 = "sha256-AOb79RiHpYnrPv/jHCijAgr4uIe+TUIsY8pmVt0b0cU=";
      fetchSubmodules = true;
    };
  });
}
