{
  stdenv,
  lib,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  qrtr,
  zstd,
  systemd,
}:
stdenv.mkDerivation rec {
  pname = "tqftpserv";
  version = "1.1.1";

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  buildInputs = [
    qrtr
    zstd
    systemd
  ];

  src = fetchFromGitHub {
    owner = "linux-msm";
    repo = "tqftpserv";
    tag = "v${version}";
    hash = "sha256-cwoAinvO2bQ6Ylx1zzh5ycE7om2vgk9uqyDJhpy6jP4=";
  };

  patches = [
    ./tqftpserv-firmware-path.diff
  ];

  meta = with lib; {
    description = "Trivial File Transfer Protocol server over AF_QIPCRTR";
    homepage = "https://github.com/linux-msm/tqftpserv";
    license = licenses.bsd3;
    maintainers = [ ];
    platforms = platforms.aarch64;
  };
}
