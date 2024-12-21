{ stdenv, fetchFromGitHub
, ruby, binutils, curl, file, gzip, lz4, mkbootimg, binwalk, zlib }:

stdenv.mkDerivation {
  pname = "mobile-nixos-autoport";
  version = "0.0.2";

  src = fetchFromGitHub {
    owner = "mobile-nixos";
    repo = "autoport";
    rev = "8958b938ab6eba5e5018580b20705bbc6d5545d4";
    sha256 = "1ksvdk81paax3pzki5ikf6p5q7hpx2bg0abc1pgrv2avzqq9nnfh";
  };

  buildInputs = [
    ruby

    binutils
    curl
    file
    gzip
    lz4
    mkbootimg
    binwalk
    zlib
  ];

  installPhase = ''
    mkdir -p $out/lib/autoport
    cp -prf . $out/lib/autoport

    mkdir -p $out/bin
    ln -sf $out/lib/autoport/autoport.rb $out/bin/autoport
  '';
}
