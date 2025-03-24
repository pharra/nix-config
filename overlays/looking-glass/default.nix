self: super: {
  looking-glass-client = super.looking-glass-client.overrideAttrs (oldAttrs: rec {
    version = "B7-25-bf59e451";
    src = super.fetchFromGitHub {
      owner = "gnif";
      repo = "LookingGlass";
      rev = "bf59e45118abde44ae373e7263256cb788b78396";
      sha256 = "sha256-628PXUboB7keNRhuEeA2Hixb8R0ZV+0gJHHkrbkp37g=";
      fetchSubmodules = true;
    };
    postUnpack = ''
      echo ${version} > source/VERSION
      export sourceRoot="source/client"
    '';
  });
}
