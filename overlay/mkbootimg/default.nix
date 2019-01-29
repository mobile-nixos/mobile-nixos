{stdenv, fetchurl}:

let
  version = "2017.12.13";
in
# https://github.com/osm0sis/mkbootimg/blob/2017.12.13/bootimg.h
# This builds the MSM-specific bootimgs...
# This is... not entirely bad, but not good either.
# We will probably need to make it available as msm-mkbootimg...
# MAIN difference is this:
#  * https://github.com/osm0sis/mkbootimg/blob/015be7ed1001f60c9d621970cab71577d396f452/bootimg.h#L46
# This is in place of the `uint32_t header_version` field.
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
