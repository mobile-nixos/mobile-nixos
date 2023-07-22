{ stdenv, lib, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "bootlogd";
  version = "2023-07-20";

  src = fetchFromGitHub {
    owner = "mobile-nixos";
    repo = "bootlogd";
    rev = "b9a89f30c1c6987eeb4277a071808621d6251f4e";
    sha256 = "sha256-9XC1NiOEU3+fk5qFhSFpn1Bb+ydoloDFZn0BPxTstV4=";
  };

  sourceRoot = "source/src";

  makeFlags = [
    "PREFIX=${placeholder "out"}"
  ];

  meta = with lib; {
    license = licenses.gpl2;
  };
}
