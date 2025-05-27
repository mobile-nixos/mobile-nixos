{ stdenv, lib, fetchFromGitHub, qrtr, xz }:

stdenv.mkDerivation {
  pname = "pd-mapper";
  version = "unstable-2024-06-19";

  buildInputs = [ qrtr xz ];

  src = fetchFromGitHub {
    owner = "linux-msm";
    repo = "pd-mapper";
    rev = "e7c42e1522249593302a5b8920b9e7b42dc3f25e";
    hash = "sha256-gTUpltbY5439IEEvnxnt8WOFUgfpQUJWr5f+OB12W8A=";
  };

  patches = [
    ./pd-mapper-firmware-path.diff
  ];

  installFlags = [ "prefix=$(out)" ];

  meta = with lib; {
    description = "Qualcomm PD mapper";
    homepage = "https://github.com/linux-msm/pd-mapper";
    license = licenses.bsd3;
    platforms = platforms.aarch64;
  };
}
