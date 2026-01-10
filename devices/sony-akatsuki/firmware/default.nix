{ lib
, fetchFromGitLab
, runCommand
}:

let
  baseFw = fetchFromGitLab {
    owner = "phodina";
    repo = "firmware-sony-akatsuki";
    rev = "master";
    hash = "sha256-WBQfSRmK8rNLAXSsZy/U3kb/s0JlR0IPDcqXNCvTYXY=";
  };
in runCommand "oneplus-sdm845-firmware" {
  inherit baseFw;
  # We make no claims that it can be redistributed.
  meta.license = lib.licenses.unfree;
} ''
  mkdir -p $out/lib/firmware
  cp -r $baseFw/lib/firmware/* $out/lib/firmware/
  chmod +w -R $out
  rm -rf $out/lib/firmware/postmarketos
  cp -r $baseFw/lib/firmware/postmarketos/* $out/lib/firmware
''

