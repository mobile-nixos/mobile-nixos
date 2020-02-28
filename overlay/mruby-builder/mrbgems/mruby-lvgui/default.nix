{ mrbgems
, callPackage
, fetchFromGitHub
, pkg-config

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
    rev = "d281e8b59f7e70709b7cbb993a84148eaa415302";
    sha256 = "1ial5lhwl5izn65i5ycpkz3vkmzfmf72w7rx8xb337qnarh4k60z";
  };

  gemBuildInputs = [
    lvgui
  ] ++ lvgui.buildInputs;
  gemNativeBuildInputs = [
    pkg-config
  ];
}
