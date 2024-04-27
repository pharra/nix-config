self: super: {
  looking-glass-client = super.looking-glass-client.overrideAttrs (oldAttrs: rec {
    version = "B7-rc1-21-ecd3692e";
    src = super.fetchFromGitHub {
      owner = "gnif";
      repo = "LookingGlass";
      rev = "ecd3692e1e76c1ca9d89854af5343a92eba030e1";
      sha256 = "sha256-GZkEaWuJL13LIT/w8ag06l3pO+V4Poo1bC9MmGYvLDI=";
      fetchSubmodules = true;
    };
    patches = [];
    postUnpack = ''
      echo ${version} > source/VERSION
      export sourceRoot="source/client"
    '';
  });
}
