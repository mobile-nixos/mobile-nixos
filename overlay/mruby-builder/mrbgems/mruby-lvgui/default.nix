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
    rev = "1c251ec97da1e4d3e99f0b9674b387c990211906";
    sha256 = "03bhksn2rzixxl8dk7viw2avw5cv4zpfpkcijrxjy4cc76f1wkja";
  };

  gemBuildInputs = [
    lvgui
  ] ++ lvgui.buildInputs;
  gemNativeBuildInputs = [
    pkg-config
  ];
}
