self: super: {
  looking-glass-client = super.looking-glass-client.overrideAttrs (oldAttrs: rec {
    src = super.fetchFromGitHub {
      owner = "gnif";
      repo = "LookingGlass";
      rev = "219c73edbe33cfb34b5f4d1ea64937e8441cab44";
      sha256 = "sha256-WGhkKzEmrnvMRzcY4Y9rMWBEzXOlohfeD2EmuNQWCEk=";
      fetchSubmodules = true;
    };
  });
}
