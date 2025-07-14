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
  pname = "hexagonrpc";
  version = "unstable-2025-05-12";

  src = fetchFromGitHub {
    owner = "linux-msm";
    repo = "hexagonrpc";
    rev = "e52da43a6343aa6264f784ea2d291e20d6e363e5";
    hash = "sha256-AMtp5eJNFBHkquCV8uYBjYwk7wjEsryZdJRj2QFvE+Y=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  buildInputs = [ systemd ];
  buildSystem = "meson";

  meta = with lib; {
    description = "Qualcomm HexagonFS daemon";
    homepage = "https://github.com/linux-msm/hexagonrpc";
    license = licenses.gpl3Plus;
    platforms = platforms.aarch64;
  };
}
