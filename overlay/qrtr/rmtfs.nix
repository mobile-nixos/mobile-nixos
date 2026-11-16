{
  stdenv,
  lib,
  fetchFromGitHub,
  udev,
  qrtr,
  qmic,
}:
stdenv.mkDerivation rec {
  pname = "rmtfs";
  version = "1.2";

  buildInputs = [
    udev
    qrtr
    qmic
  ];

  src = fetchFromGitHub {
    owner = "linux-msm";
    repo = "rmtfs";
    tag = "v${version}";
    hash = "sha256-fjyiSl9a98goqd/tQSylcSZFM5NAK9Kaa+5M28wa78U=";
  };

  installFlags = [ "prefix=$(out)" ];

  meta = with lib; {
    description = "Qualcomm Remote Filesystem Service";
    homepage = "https://github.com/linux-msm/rmtfs";
    license = licenses.bsd3;
    maintainers = [ ];
    platforms = platforms.aarch64;
  };
}
