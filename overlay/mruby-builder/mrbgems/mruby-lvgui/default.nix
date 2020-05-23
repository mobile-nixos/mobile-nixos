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
    rev = "eb6e40c81a63cc67b14740200966603463f426bf";
    sha256 = "1zqlhg409xx3da2cgrcmz9p9zc9cni2q25yi5vcb3naahpylbff4";
  };

  gemBuildInputs = [
    lvgui
  ] ++ lvgui.buildInputs;
  gemNativeBuildInputs = [
    pkg-config
  ];

  requiredGems = with mrbgems; [
    mruby-fiddle
  ];
}
