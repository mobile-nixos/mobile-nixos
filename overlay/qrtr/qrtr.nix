{
  stdenv,
  lib,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  systemd,
}:

stdenv.mkDerivation {
  pname = "qrtr";
  version = "unstable-2025-12-08";

  src = fetchFromGitHub {
    owner = "linux-msm";
    repo = "qrtr";
    rev = "a38e9afbe76270262dc157749602229b8b681f09";
    hash = "sha256-KxWDiTl+vbGZpB+OWYvH2/NvCWCJXZcpegAnkrG0UIo=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  buildInputs = [ systemd ];

  meta = with lib; {
    description = "Qualcomm IPC Router userspace tools and library";
    homepage = "https://github.com/linux-msm/qrtr";
    license = licenses.bsd3;
    maintainers = with lib.maintainers; [ ];
    platforms = platforms.linux;
  };
}
