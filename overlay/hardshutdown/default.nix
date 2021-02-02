{ stdenv, lib, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "hardshutdown";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "mobile-nixos";
    repo = "hardshutdown";
    rev = "6beb4b77b273bbd045870ecd8de8630b5007451b";
    sha256 = "0vxflpfx8dr5rzr9y6hm0zv7jxcc3sgisqvkyicwzg8mvl2vfshi";
  };

  makeFlags = [
    "PREFIX=${placeholder "out"}"
  ];

  meta = with lib; {
    description = "Single-call binary handling shutdown/reboot syscalls";
    license = licenses.gpl2;
  };
}
