self: super: {
  looking-glass-client = super.looking-glass-client.overrideAttrs (oldAttrs: rec {
    version = "B6-289-545e7363";
    src = super.fetchFromGitHub {
      owner = "gnif";
      repo = "LookingGlass";
      rev = "545e736389faaca29a618afd5be30ba120b96b12";
      sha256 = "sha256-re4bNwtM2qaR2NRfVKcWY8PlU1XopTBpGDliln15q6Y=";
      fetchSubmodules = true;
    };
    postUnpack = ''
      echo ${version} > source/VERSION
      export sourceRoot="source/client"
    '';
  });
}
