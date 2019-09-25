{stdenv, fetchurl}:

let
  version = "0.2";
in
stdenv.mkDerivation {
  inherit version;
  name = "msm-fb-refresher";

  src = fetchurl {
    url = "https://github.com/AsteroidOS/msm-fb-refresher/archive/v${version}.tar.gz";
    sha256 = "1w1kvk8kgmzh7v50sc24c9dkq4ix9pf65dscqzwikbaz537x5rkf";
  };

  CC = "${stdenv.cc}/bin/gcc";

  buildPhase = ''
    $CC refresher.c -o refresher.o -c
    $CC refresher.o -o msm-fb-refresher
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp -v msm-fb-refresher $out/bin/
    chmod +x $out/bin/*
  '';
}
