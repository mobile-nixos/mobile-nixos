{ stdenv
, fetchFromGitHub
, lib
, libtool
, automake
, libconfig
, pkg-config
,  autoreconfHook
} :
stdenv.mkDerivation {
  pname = "libusbgx";
  version = "0.2.0-git";
  nativeBuildInputs = [ pkg-config   autoreconfHook  ];
  buildInputs = [ libconfig ] ;
  src = fetchFromGitHub {
    owner = "linux-usb-gadgets";
    repo = "libusbgx";
    rev = "060784424609d5a4e3bce8355f788c93f09802a5";
    hash = "sha256-Z6Jmtk3sFNyvMhwMcOvHS3BgUvzJwUZRyPIEtR+CWJw=";
  };
}
