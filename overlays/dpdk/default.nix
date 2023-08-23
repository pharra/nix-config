self: super: {
  dpdk = super.dpdk.overrideAttrs (oldAttrs: rec {
    dpdkVersion = "23.07";
    version = "${dpdkVersion}";
    src = super.fetchurl {
      url = "https://fast.dpdk.org/rel/dpdk-${dpdkVersion}.tar.xz";
      sha256 = "sha256-4IYU6K65KUB9c9cWmZKJpE70A0NSJx8JOX7vkysjs9Y=";
    };
  });
}
