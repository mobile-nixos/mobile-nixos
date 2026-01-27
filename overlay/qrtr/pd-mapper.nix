{
  stdenv,
  lib,
  fetchFromGitHub,
  qrtr,
  xz,
}:
stdenv.mkDerivation {
  pname = "pd-mapper";
  # No versioned releases, so let's use the commit hash for now.
  version = "0a43c8be564feae0493b6e24b2e3e98459a4f9b6";

  buildInputs = [qrtr xz];

  src = fetchFromGitHub {
    owner = "linux-msm";
    repo = "pd-mapper";
    rev = "0a43c8be564feae0493b6e24b2e3e98459a4f9b6";
    hash = "sha256-XiEZS+hb44nD1o1Xvjnrq5ead7Nym/Yg7iCnr93qC+k=";
  };

  patches = [
    ./pd-mapper-firmware-path.diff
  ];

  installFlags = ["prefix=$(out)"];

  meta = with lib; {
    description = "Qualcomm PD mapper";
    homepage = "https://github.com/linux-msm/pd-mapper";
    license = licenses.bsd3;
    maintainers = [];
    platforms = platforms.aarch64;
  };
}
