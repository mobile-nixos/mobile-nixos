{stdenv}:

let
  version = "0.1";
in
stdenv.mkDerivation {
  inherit version;
  name = "msm-fb-handle";

  src = ./main.c;
  unpackCmd = "mkdir -v src ; cp -v $curSrc src/main.c";

  CC = "${stdenv.cc}/bin/gcc";

  buildPhase = ''
    $CC main.c -o msm-fb-handle
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp -v msm-fb-handle $out/bin/
    chmod +x $out/bin/*
  '';
}
