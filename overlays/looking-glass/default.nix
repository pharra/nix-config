self: super: {
  looking-glass-client = super.looking-glass-client.overrideAttrs (oldAttrs: rec {
    version = "B7-rc1-34-e25492a3";
    src = super.fetchFromGitHub {
      owner = "gnif";
      repo = "LookingGlass";
      rev = "b526eb3da0c6f29c74cf0c3d288cc0d3d251fbdb";
      sha256 = "sha256-r2g+0KQMr7JQXqXU1OZNmrvDre7PdaeTOuGEmlRRWBM=";
      fetchSubmodules = true;
    };
    patches = [./nanosvg-unvendor.diff];
    postUnpack = ''
      echo ${version} > source/VERSION
      export sourceRoot="source/client"
    '';
  });
}
