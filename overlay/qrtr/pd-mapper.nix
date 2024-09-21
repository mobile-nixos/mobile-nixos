{ stdenv, lib, fetchFromGitHub, qrtr }:

stdenv.mkDerivation (finalAttrs:{
  pname = "pd-mapper";
  version = "1.0";

  buildInputs = [ qrtr ];

  src = fetchFromGitHub {
    owner = "linux-msm";
    repo = "pd-mapper";
    rev = "v${finalAttrs.version}";
    hash = "sha256-vQZZ3WtZGh5OEw0EmlmT/My/cY6VRruuicsFR0YCQOw=";
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
})
