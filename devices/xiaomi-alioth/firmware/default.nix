{ lib
, fetchFromGitHub
, runCommand
}:

let
  baseFw = fetchFromGitHub {
    owner = "N1kroks";
    repo = "firmware-xiaomi-alioth";
    rev = "95dfcdf6b154c00af3e093db82015cda90f4299a";
    hash = "sha256-hk/r6p0/d/YLii1B4WHp9I9Y+QBfZOTmYefWfRNa7Lk=";
  };
in
runCommand "xiaomi-alioth-firmware" {
  inherit baseFw;
  meta.license = lib.licenses.unfree;
} ''
  mkdir -p $out/lib/firmware $out/usr/share/qcom
  cp -r $baseFw/lib/firmware/* $out/lib/firmware/
  cp -r $baseFw/usr/share/qcom/* $out/usr/share/qcom/
''
