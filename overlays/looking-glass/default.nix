self: super: {
  looking-glass-client = super.looking-glass-client.overrideAttrs (oldAttrs: rec {
    version = "B7-rc1-15-7f515c54";
    src = super.fetchFromGitHub {
      owner = "gnif";
      repo = "LookingGlass";
      rev = "7f515c54b399aef2c9e010e77ba91975e7f22928";
      sha256 = "sha256-yVEwUPmbna9y3Q1w1nj6RPEdh5Npb+tZBEm2OwqfWfE=";
      fetchSubmodules = true;
    };
    postUnpack = ''
      echo ${version} > source/VERSION
      export sourceRoot="source/client"
    '';
  });
}
