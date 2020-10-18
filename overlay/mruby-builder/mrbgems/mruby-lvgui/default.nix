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
    rev = "286e49486dee408bca33e22a3ea8059054f69a5a";
    sha256 = "1hg9i0icgy6ghmsa4znrwb889x7p191zidypk1n8m5jrv3aijix5";
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
