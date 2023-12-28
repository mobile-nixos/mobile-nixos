{ lib
, fetchFromGitLab
, runCommand
}:

let
  baseFw = fetchFromGitLab {
    owner = "sdm845-mainline";
    repo = "firmware-xiaomi-beryllium";
    rev = "9ce691fb2e629476a33e037bdcd039cd7e8c5a6c";
    sha256 = "sha256-R/x7LxDyPU3s30y2PJNw72vo7wAA3Di8Iy61syffEKE=";
  };
in runCommand "xiaomi-sdm845-firmware" { inherit baseFw; } ''
  mkdir -p $out/lib/firmware
  cp -r $baseFw/lib/firmware/* $out/lib/firmware/
  chmod +w -R $out
''
