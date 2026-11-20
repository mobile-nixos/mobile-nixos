{ stdenv
, fetchFromGitHub
, libconfig
, libusbgx
, cmake
, pkg-config
}:

stdenv.mkDerivation rec {
  pname = "gt";
  version = "git";
  nativeBuildInputs = [
    cmake
    pkg-config
  ];
  buildInputs = [
    libconfig
    libusbgx
  ];
  postPatch = ''
    sed -i.bak -e 's/VERSION 2.8/VERSION 3.5/' CMakeLists.txt
  '';
  sourceRoot = "${src.name}/source";
  src = fetchFromGitHub {
    owner = "linux-usb-gadgets";
    repo = "gt";
    rev = "7f9c45d98425a27444e49606ce3cf375e6164e8e";
    hash = "sha256-km4U+t4Id2AZx6GpH24p2WNmvV5RVjJ14sy8tWLCQsk=";
  };
}
