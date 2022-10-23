{ stdenv, lib, fetchFromGitHub, qrtr }:

stdenv.mkDerivation {
  pname = "pd-mapper";
  version = "unstable-2022-02-08";

  buildInputs = [ qrtr ];

  src = fetchFromGitHub {
    owner = "andersson";
    repo = "pd-mapper";
    rev = "9d78fc0c6143c4d1b7198c57be72a6699ce764c4";
    hash = "sha256-vQZZ3WtZGh5OEw0EmlmT/My/cY6VRruuicsFR0YCQOw=";
  };

  patches = [
    ./pd-mapper-firmware-path.diff
  ];

  installFlags = [ "prefix=$(out)" ];

  meta = with lib; {
    description = "Qualcomm PD mapper";
    homepage = "https://github.com/andersson/pd-mapper";
    license = licenses.bsd3;
    platforms = platforms.aarch64;
  };
}
