{
  stdenv,
  lib,
  buildGoModule,
  fetchFromGitHub,
  buildNpmPackage,
}: let
  source = fetchFromGitHub {
    owner = "pharra";
    repo = "spdk-dashboard";
    rev = "ab2576ccf0c047bd786ed5577ebf933af1fcb284";
    hash = "sha256-Jcb1PQM9SfAIxJR8B+xZbC9gc3wsLTtoElV2v9wTuo0=";
  };
  # spdk-dashboard-nodejs = buildNpmPackage rec {
  #   nodejs = nodejs_21;
  #   pname = "spdk-dashboard-nodejs";
  #   version = "unstable-2023-01-23";
  #   src = source;
  #   npmWorkspace = "public";
  #   postPatch = ''
  #     cp public/package-lock.json .
  #   '';
  #   npmDepsHash = "sha256-TM9Z/hQ6Wzko+2Y3xXZQqK8Vk0LV8SNaPu3t2gkMJPI=";
  #   npmBuildScript = "build-dist";
  #   meta = with lib; {
  #     description = "A fancy realtime dashboard for SPDK (Storage Performance Development Kit) storage metric";
  #     homepage = "https://github.com/fangli/spdk-dashboard";
  #     license = licenses.mit;
  #     maintainers = with maintainers; [];
  #   };
  # };
in
  buildGoModule rec {
    pname = "spdk-dashboard";
    version = "unstable-2023-01-23";

    src = source;
    vendorHash = "sha256-ZZyg8KUqwKUOEDFeRiaxjSnHWhMRF8AP04agG3nesw4=";

    # postUnpack = ''
    #   cp -r ${spdk-dashboard-nodejs}/dist $src/public
    # '';

    meta = with lib; {
      description = "A fancy realtime dashboard for SPDK (Storage Performance Development Kit) storage metric";
      homepage = "https://github.com/fangli/spdk-dashboard";
      license = licenses.mit;
      maintainers = with maintainers; [];
    };
  }
