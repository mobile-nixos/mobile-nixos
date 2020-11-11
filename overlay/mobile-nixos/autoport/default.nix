{ stdenv, fetchFromGitHub
, ruby, binutils, curl, file, gzip, lz4, mkbootimg, python3Packages, zlib }:

stdenv.mkDerivation {
  pname = "mobile-nixos-autoport";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "mobile-nixos";
    repo = "autoport";
    rev = "e439066d09154e9123890c2e4fc6d6323c530640";
    sha256 = "0x548k91q17m1zf5r8kjwiyxlsvf55n60bw0ljhw71pcn0xdlic4";
  };

  buildInputs = [
    ruby

    binutils
    curl
    file
    gzip
    lz4
    mkbootimg
    python3Packages.binwalk
    zlib
  ];

  installPhase = ''
    mkdir -p $out/lib/autoport
    cp -prf . $out/lib/autoport

    mkdir -p $out/bin
    ln -sf $out/lib/autoport/autoport.rb $out/bin/autoport
  '';
}
