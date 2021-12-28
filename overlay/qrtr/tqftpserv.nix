{ stdenv, lib, fetchFromGitHub, qrtr }:

stdenv.mkDerivation {
  pname = "tqftpserv";
  version = "unstable-2020-02-07";

  buildInputs = [ qrtr ];

  src = fetchFromGitHub {
    owner = "andersson";
    repo = "tqftpserv";
    rev = "783425b550de2a359db6aa3b41577c3fbaae5903";
    hash = "sha256-Qybmd/mXhKotCem/xN0bOvWyAp2VJf+Hdh6PQyFnd3s==";
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
