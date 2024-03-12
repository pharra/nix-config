self: super: {
  looking-glass-client = super.looking-glass-client.overrideAttrs (oldAttrs: rec {
    version = "B7-rc1-13-dc9065b6";
    src = super.fetchFromGitHub {
      owner = "gnif";
      repo = "LookingGlass";
      rev = "dc9065b62f2c9a7502ef13792644b77d0c38f3a9";
      sha256 = "sha256-8AzND+xf/u1a7Ye07+IB8dFJCm3Czb9k5ECGibOgSlI=";
      fetchSubmodules = true;
    };
    postUnpack = ''
      echo ${version} > source/VERSION
      export sourceRoot="source/client"
    '';
  });
}
