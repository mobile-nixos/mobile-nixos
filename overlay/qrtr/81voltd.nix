{ lib
, stdenv
, fetchFromGitLab
, meson
, ninja
, pkg-config
, modemmanager
, glib
, qrtr
, qmic
}:

stdenv.mkDerivation rec {
  pname = "81voltd";
  version = "1.0.0";

  src = fetchFromGitLab {
    owner = "flamingradian";
    repo = "81voltd";
    rev = "v${version}";
    hash = "sha256-w1HxF1tUiD44Rqox6mr3A+Bd0Uv6a/K53f17QxZu0fo=";
  };

  buildInputs = [
    modemmanager
    glib
    qrtr
  ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    qmic
  ];

  installPhase = ''
    runHook preBuild
    mkdir -p "$out/bin"
    install 81voltd "$out/bin"
    runHook postBuild
  '';

  meta = with lib; {
    description = "Server-side implementation of the QMI IMS Data service";
    homepage = "https://gitlab.com/flamingradian/81voltd";
    license = licenses.gpl2Only;
    mainProgram = "81voltd";
    platforms = platforms.all;
  };
}
