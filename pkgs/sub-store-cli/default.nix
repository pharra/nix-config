{
  stdenv,
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "sub-store-cli";
  version = "0.0.10";

  src = fetchFromGitHub {
    owner = "sub-store-org";
    repo = "Sub-Store-Manager-Cli";
    rev = version;
    hash = "sha256-xzXOAm1BalbJr7lShdDo+f3CHQn91rkeLdK4KksR628=";
  };
  vendorHash = "sha256-6TEOMYS3fGXYgjw6p0lfRmd52/p5iK3NZnDEAZiu17E=";

  meta = with lib; {
    description = "A cli tool for https://github.com/sub-store-org/Sub-Store base docker.";
    homepage = "https://github.com/sub-store-org/Sub-Store-Manager-Cli";
    license = licenses.gpl3;
    maintainers = with maintainers; [];
  };
}
