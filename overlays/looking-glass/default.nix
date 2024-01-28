self: super: {
  looking-glass-client = super.looking-glass-client.overrideAttrs (oldAttrs: rec {
    version = "B6-246-e376e6fb";
    src = super.fetchFromGitHub {
      owner = "gnif";
      repo = "LookingGlass";
      rev = "e376e6fb537477b6f01a2fb7008ff0df52051821";
      sha256 = "sha256-MH1oqOZwanb+mGAux6RCYfsYjTiMOMg9wdltcK/ivR0=";
      fetchSubmodules = true;
    };
    postUnpack = ''
      echo ${version} > source/VERSION
      export sourceRoot="source/client"
    '';
  });
}
