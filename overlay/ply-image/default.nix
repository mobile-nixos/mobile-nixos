{stdenv, fetchgit, libpng, libdrm, pkg-config}:

let
  version = "2016-01-11";
in
stdenv.mkDerivation {
  inherit version;
  name = "ply-image";

  src = fetchgit {
    url = "https://chromium.googlesource.com/chromiumos/third_party/ply-image";
    rev = "6cf4e4cd968bb72ade54e423e2b97eb3a80c6de9";
    sha256 = "152hh9r04hjqrpfqskqh876vlf5dfqiwx719nyjq1y2qr8a9akm7";
  };

  patches = [
    ./99_additional_debug.diff
    ./99_msm-fb.diff
  ];

  nativeBuildInputs = [
    pkg-config
  ];
  buildInputs = [
    libpng
    libdrm
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp -v src/ply-image $out/bin/
  '';
}
