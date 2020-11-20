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
    rev = "c82c82e5326540faa2ac47259adbf6254cd1994f";
    sha256 = "11xpa1fvnv6h0wkjj7h5l4vsyjvbffz4mdcxcdv21nxsdgrsdzdl";
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
