{ stdenv, lib, fetchFromGitHub, udev, qrtr, qmic }:

stdenv.mkDerivation {
  pname = "rmtfs";
  version = "unstable-2022-07-18";

  buildInputs = [ udev qrtr qmic ];

  src = fetchFromGitHub {
    owner = "andersson";
    repo = "rmtfs";
    rev = "695d0668ffa6e2a4bf6e676f3c58a444a5d67690";
    hash = "sha256-00KOjdkwcAER261lleSl7OVDEAEbDyW9MWxDd0GI8KA=";
  };

  installFlags = [ "prefix=$(out)" ];

  meta = with lib; {
    description = "Qualcomm Remote Filesystem Service";
    homepage = "https://github.com/andersson/rmtfs";
    license = licenses.bsd3;
    platforms = platforms.aarch64;
  };
}
