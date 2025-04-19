{ fetchFromGitHub
, runCommand
}:

let
  baseFw = fetchFromGitHub {
    owner = "mainlining";
    repo = "firmware-nothing-spacewar";
    rev = "428184b45f1294a0e66979f570902de84883e1fc";
    hash = "sha256-avwMvWlNMnrVglzjeDOTFshfr4Hwh0ASvopseHuXBfo=";
  };
in runCommand "nothing-spacewar-firmware" { inherit baseFw; } ''
  mkdir -p $out/lib/firmware
  cp -r $baseFw/lib/firmware/* $out/lib/firmware/
  chmod +w -R $out
''
