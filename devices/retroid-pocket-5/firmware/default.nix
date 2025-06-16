{
  lib,
  fetchFromGitHub,
  runCommand,
}:

let
  baseFw = fetchFromGitHub {
    owner = "tajo48";
    repo = "sm8250-mainline";
    rev = "47bb4e41a1deba9b547515e619e854f415eef4aa";
    sha256 = "sha256-WB6I25lP5UIn9lOqYvVLAvBsXca6qk3D6YuFDa3sVaM=";
  };
in
runCommand "retroid-sm8250-firmware"
  {
    inherit baseFw;
    # We make no claims that it can be redistributed.
    # meta.license = lib.licenses.unfree; # TODO uncomment later
  }
  ''
    mkdir -p $out/lib/firmware
    cp -r $baseFw/lib/firmware/* $out/lib/firmware/
    chmod +w -R $out
    rm -rf $out/lib/firmware/postmarketos
    cp -r $baseFw/lib/firmware/postmarketos/* $out/lib/firmware
  ''
