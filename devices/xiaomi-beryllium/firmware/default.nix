{ lib
, fetchFromGitLab
, runCommand
}:

let
  baseFw = fetchFromGitLab {
    owner = "sdm845-mainline";
    repo = "firmware-xiaomi-beryllium";
    rev = "66ec241f43f26e8e8a2c6f18858c92f1a7fb16e4";
    sha256 = "sha256-WhzxM7oooFNbMEQE2OQDFmTTsbvHpuxUtxYJYcPE/7E=";
  };
in runCommand "xiaomi-sdm845-firmware" { inherit baseFw; } ''
  mkdir -p $out/lib/firmware
  cp -r $baseFw/lib/firmware/* $out/lib/firmware/
  chmod +w -R $out
''
