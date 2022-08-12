{ stdenv
, fetchFromGitHub
, libconfig
, libusbgx
, cmake

# , libtool
# , automake

, pkg-config
# ,  autoreconfHook
} :
stdenv.mkDerivation rec {
  pname = "gt";
  version = "git";
  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ libconfig libusbgx ] ;
  sourceRoot = "${src.name}/source";
  patches = [
#    ./0001-allow-specify-config-file.patch
  ];
  src = fetchFromGitHub {
    owner = "linux-usb-gadgets";
    repo = "gt";
    rev = "7f9c45d98425a27444e49606ce3cf375e6164e8e";
    hash = "sha256-km4U+t4Id2AZx6GpH24p2WNmvV5RVjJ14sy8tWLCQsk=";
  };
}
