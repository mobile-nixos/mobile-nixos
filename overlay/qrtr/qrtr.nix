{ stdenv, lib, fetchFromGitHub, meson, ninja, pkg-config, systemd }:

stdenv.mkDerivation {
  pname = "qrtr";
  version = "unstable-2025-03-01";

  src = fetchFromGitHub {
    owner = "linux-msm";
    repo = "qrtr";
    rev = "5923eea97377f4a3ed9121b358fd919e3659db7b";
    hash = "sha256-iHjF/2SQsvB/qC/UykNITH/apcYSVD+n4xA0S/rIfnM=";
  };

  nativeBuildInputs = [ meson ninja pkg-config ];
  buildInputs = [ systemd ];
  buildSystem = "meson";

  meta = with lib; {
    description = "QMI IDL compiler";
    homepage = "https://github.com/linux-msm/qrtr";
    license = licenses.bsd3;
    platforms = platforms.aarch64;
  };
}
