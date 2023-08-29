self: super: {
  ipxe = super.ipxe.overrideAttrs (oldAttrs: rec {
    # version = "unstable-2023-08-27";
    # src = super.fetchFromGitHub {
    #   owner = "ipxe";
    #   repo = "ipxe";
    #   rev = "9e99a55b317f5da66f5110891b154084b337a031";
    #   hash = "sha256-fJeDgm+OaItshWFliq08Y0BPDD2FCkezeEp7trqWNjA=";
    # };
  });
}
