{stdenv, fetchurl}:

let
  version = "2019.04.13";
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
    sha256 = "0pwxc1wn38a159lcwlsri4dc8b7kpnfyryi2l75i4a61wxqb94kj";
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
