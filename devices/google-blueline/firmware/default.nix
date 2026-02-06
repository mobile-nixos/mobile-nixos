{ lib
, fetchFromGitLab
, runCommand
}:

let
  baseFw = fetchFromGitLab {
    owner = "phodina";
    repo = "firmware-google-blueline";
    rev = "c0dd16a522f8c469792681a4ea0017dc58b20b56";
    hash = "sha256-fTbTV74qNQ9FSt78w+mvLF8CKBrThPLO/UhFvXYcO44=";
  };
in runCommand "firmware-google-blueline" {
  inherit baseFw;
  # We make no claims that it can be redistributed.
  meta.license = lib.licenses.unfree;
} ''
  mkdir -p $out/lib/firmware
  # Copy firmware, but handle the case where source already has lib/firmware in path
  if [ -d $baseFw/lib/firmware ]; then
    cp -r $baseFw/lib/firmware/* $out/lib/firmware/
  else
    cp -r $baseFw/* $out/lib/firmware/
  fi
''
