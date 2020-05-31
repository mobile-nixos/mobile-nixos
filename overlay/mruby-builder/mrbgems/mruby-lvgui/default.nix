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
    rev = "73854c219fd975fc1e82ac582381a4a51af2d3c1";
    sha256 = "0plvjn8sxgjz6n3546aqkrdqkx32mzsb0d938svpd9l223nihdh8";
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
