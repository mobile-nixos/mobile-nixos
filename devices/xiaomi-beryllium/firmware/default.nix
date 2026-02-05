{ lib
, fetchFromGitLab
, runCommand
}:

let
  baseFw = fetchFromGitLab {
    owner = "sdm845-mainline";
    repo = "firmware-xiaomi-beryllium";
    rev = "master";
    hash = "sha256-at+V+94Kl4l++Ih5gPlxPm/9JCparU8yImQdJP/QGKI=";
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
