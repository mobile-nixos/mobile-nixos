{ stdenv, lib, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "bootlogd";
  version = "2020-02-02";

  src = fetchFromGitHub {
    owner = "mobile-nixos";
    repo = "bootlogd";
    rev = "e5af793da15def578eb3b25cb2c02196267021b1";
    sha256 = "0m6y1369xs8hds66q5z2bxd80vxwnkqsnppmkfqk6i1d2259i903";
  };

  sourceRoot = "source/src";

  makeFlags = [
    "PREFIX=${placeholder "out"}"
  ];

  meta = with lib; {
    license = licenses.gpl2;
  };
}
