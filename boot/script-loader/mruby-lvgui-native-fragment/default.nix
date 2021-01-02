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
  # Dirty since `default.nix` and `lvgui.nix` modifications will
  # needlessly cause a rebuild, but good enough in reality.
  src = ./.;

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
