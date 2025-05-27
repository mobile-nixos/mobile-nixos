{ stdenv, lib, fetchFromGitHub, udev, qrtr, qmic }:

stdenv.mkDerivation {
  pname = "rmtfs";
  version = "unstable-2025-05-01";

  buildInputs = [ udev qrtr qmic ];

  src = fetchFromGitHub {
    owner = "linux-msm";
    repo = "rmtfs";
    rev = "b61c22b1cd01f4b1f5f48192f0700aa398de31a3";
    hash = "sha256-O/o8C5YUQX/kVs89mCY/ip2cKsc/W0d0yMTy/QOETa0=";
  };

  installFlags = [ "prefix=$(out)" ];

  meta = with lib; {
    description = "Qualcomm Remote Filesystem Service";
    homepage = "https://github.com/linux-msm/rmtfs";
    license = licenses.bsd3;
    platforms = platforms.aarch64;
  };
}
