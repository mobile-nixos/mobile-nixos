{ stdenv
, fetchFromGitHub
, libconfig
, pkg-config
, autoreconfHook
}:

stdenv.mkDerivation {
  pname = "libusbgx";
  version = "unstable-2021-10-31";
  nativeBuildInputs = [
    pkg-config
    autoreconfHook
  ];
  buildInputs = [
    libconfig
  ];
  src = fetchFromGitHub {
    owner = "linux-usb-gadgets";
    repo = "libusbgx";
    rev = "060784424609d5a4e3bce8355f788c93f09802a5";
    hash = "sha256-Z6Jmtk3sFNyvMhwMcOvHS3BgUvzJwUZRyPIEtR+CWJw=";
  };
}
