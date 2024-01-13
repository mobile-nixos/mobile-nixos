{ stdenv, lib, fetchFromGitHub, qrtr }:

stdenv.mkDerivation {
  pname = "tqftpserv";
  version = "unstable-2020-02-07";

  buildInputs = [ qrtr ];

  src = fetchFromGitHub {
    owner = "andersson";
    repo = "tqftpserv";
    rev = "de42697a2466cc5ee267ffe36ab4e8494f005fb0";
    hash = "sha256-FAj1R9CNnYICpEgoiddHPLTXJsvZiDvYsiYPaosMJxI=";
  };

  patches = [
    ./tqftpserv-firmware-path.diff
  ];

  installFlags = [ "prefix=$(out)" ];

  meta = with lib; {
    description = "Trivial File Transfer Protocol server over AF_QIPCRTR";
    homepage = "https://github.com/andersson/tqftpserv";
    license = licenses.bsd3;
    platforms = platforms.aarch64;
  };
}
