{ mrbgems
, callPackage
, fetchFromGitHub
, pkg-config
, buildPackages

# Configuration
, withSimulator ? false
}:
let
  # This is an implementation detail of this gem.
  # Even if unusual, let's keep it private.
  lvgui = (callPackage ./lvgui.nix {
    inherit withSimulator;
  });
in
mrbgems.mkGem {
  src = fetchFromGitHub {
    repo = "mruby-lvgui";
    owner = "mobile-nixos";
    rev = "85a6e927bbf66fe589721795357ee2fd8eaae929";
    sha256 = "1v35p4145zf1icdkmzwz9k2xvkhjb61df4lbgs8ljjmypjadwhl0";
  };

  gemBuildInputs = [
    lvgui
  ] ++ lvgui.buildInputs;
  gemNativeBuildInputs = [
    buildPackages.pkg-config
  ];

  requiredGems = with mrbgems; [
    mruby-fiddle
  ];
}
