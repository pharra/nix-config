self: super: {
  looking-glass-client = super.looking-glass-client.overrideAttrs (oldAttrs: rec {
    version = "B6-234-c2237f29";
    src = super.fetchFromGitHub {
      owner = "gnif";
      repo = "LookingGlass";
      rev = "c2237f29ae891316b32a534e5d0dfec6616d6294";
      sha256 = "sha256-5arzCjaRrR6wAcSoKLDzOil56gQTw2YXvbXKmkcipAY=";
      fetchSubmodules = true;
    };
    postUnpack = ''
      echo ${version} > source/VERSION
      export sourceRoot="source/client"
    '';
  });
}
