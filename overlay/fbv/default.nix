{stdenv, fetchurl, libpng, libjpeg, libungif, getopt}:

let
  version = "1.0b";
in
stdenv.mkDerivation {
  inherit version;
  name = "fbv";

  # Hmm, their library detection seems screwy.
  # This is why I need to repeat both sets.
  buildInputs = [
    libpng
    libjpeg
    libungif
    getopt
  ];

  nativeBuildInputs = [
    libpng
    libjpeg
    libungif
    getopt
  ];

  preConfigure = ''
    # Using --libs= doesn't work.
    export LDFLAGS="-lpng -lz -ljpeg -lungif"
  '';

  postPatch = ''
    substituteInPlace Makefile --replace "CC${"\t"}= gcc " "CC = $CC";
    substituteInPlace Makefile --replace '$(CC) $(LDFLAGS)' '$(LD) $(LDFLAGS)'
  '';

  configurePlatforms = [ ];

  src = fetchurl {
    url = "http://s-tech.elsat.net.pl/fbv/fbv-${version}.tar.gz";
    sha256 = "0g5b550vk11l639y8p5sx1v1i6ihgqk0x1hd0ri1bc2yzpdbjmcv";
  };

  preInstall = ''
    mkdir -p $out/bin
    mkdir -p $out/man/man1
  '';
}
