self: super: {
  looking-glass-client = super.looking-glass-client.overrideAttrs (oldAttrs: rec {
    version = "B7-rc1-34-e25492a3";
    src = super.fetchFromGitHub {
      owner = "gnif";
      repo = "LookingGlass";
      rev = "e25492a3a36f7e1fde6e3c3014620525a712a64a";
      sha256 = "sha256-DBmCJRlB7KzbWXZqKA0X4VTpe+DhhYG5uoxsblPXVzg=";
      fetchSubmodules = true;
    };
    patches = [./nanosvg-unvendor.diff];
    postUnpack = ''
      echo ${version} > source/VERSION
      export sourceRoot="source/client"
    '';
  });
}
