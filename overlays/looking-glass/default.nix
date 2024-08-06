self: super: {
  looking-glass-client = super.looking-glass-client.overrideAttrs (oldAttrs: rec {
    version = "B7-rc1-30-d060e375";
    src = super.fetchFromGitHub {
      owner = "gnif";
      repo = "LookingGlass";
      rev = "d060e375ea47e4ca38894ea7bf02a85dbe29b1f8";
      sha256 = "sha256-DuCznF2b3kbt6OfoOUD3ijJ1im7anxj25/xcQnIVnWc=";
      fetchSubmodules = true;
    };
    patches = [];
    postUnpack = ''
      echo ${version} > source/VERSION
      export sourceRoot="source/client"
    '';
  });
}
