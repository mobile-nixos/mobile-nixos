{stdenv, fetchurl}:

stdenv.mkDerivation rec {
  pname = "mkbootimg";
  version = "2020.05.18";

  src = fetchurl {
    url = "https://github.com/osm0sis/mkbootimg/archive/${version}.tar.gz";
    sha256 = "1zz06x31rak9sv5v01kj3cvqvzh5qvq34p00paw5p3jl0lxvnvwc";
  };

  # Using makeFlags doesn't work due to the args being passed as well
  # Replacing is required for cross-compilation
  postPatch = ''
    substituteInPlace Makefile \
      --replace "AR = ar rcv" "AR = ${stdenv.cc.bintools.targetPrefix}ar rcv"
    substituteInPlace libmincrypt/Makefile \
      --replace "AR = ar rc" "AR = ${stdenv.cc.bintools.targetPrefix}ar rc"
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp -v mkbootimg $out/bin/
    cp -v unpackbootimg $out/bin/
    chmod +x $out/bin/*
  '';
}
