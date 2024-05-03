self: super: {
  tailscale = super.tailscale.overrideAttrs (oldAttrs: rec {
    subPackages = ["cmd/tailscaled" "cmd/derper"];
  });
}
