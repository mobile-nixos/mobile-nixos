{stdenv, fetchurl, python2, dtc, python2Packages}:

let
  version = "2017.12.13";
in
stdenv.mkDerivation {
  inherit version;
  name = "mkbootimg";

  src = fetchurl {
    url = "https://github.com/osm0sis/mkbootimg/archive/${version}.tar.gz";
    sha256 = "1wyn0a2nxwyz3j6yx4vmm67inrsh83h24sfig6y7ww249miix2xp";
  };

  postPatch = ''
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp -v mkbootimg $out/bin/
    cp -v unpackbootimg $out/bin/
    chmod +x $out/bin/*
  '';

  # TODO meta url : https://source.codeaurora.org/quic/kernel/skales/plain/dtbTool
}
