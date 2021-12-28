{ stdenv, lib, fetchFromGitHub, udev, qrtr, qmic }:

stdenv.mkDerivation {
  pname = "rmtfs";
  version = "unstable-2021-04-09";

  buildInputs = [ udev qrtr qmic ];

  src = fetchFromGitHub {
    owner = "andersson";
    repo = "rmtfs";
    rev = "b08ef6f98ec567876d7d45f15c85c6ed00d7c463";
    hash = "sha256-v7xcbo+KYPqUr0xNjj4IZrVmsMHx99Cmy2Sm5Z4WDaQ=";
  };

  installFlags = [ "prefix=$(out)" ];

  meta = with lib; {
    description = "Qualcomm Remote Filesystem Service";
    homepage = "https://github.com/andersson/rmtfs";
    license = licenses.bsd3;
    platforms = platforms.aarch64;
  };
}
