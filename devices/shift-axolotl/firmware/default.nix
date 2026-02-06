{ lib
, fetchFromGitLab
, runCommand
, zstd
}:

let
  baseFw = fetchFromGitLab {
    owner = "sdm845-mainline";
    repo = "firmware-shift-sdm845";
    rev = "080579884db2fca768ad5599d01ebe2ced3193f3";
    sha256 = "sha256-X/FuWx6KU8uY2C8akTWykVB/MYPHopaEdVdXIkvNmVU=";
  };
in runCommand "shift-axolotl-firmware" {
  inherit baseFw;
  nativeBuildInputs = [ zstd ];
  # We make no claims that it can be redistributed.
  meta.license = lib.licenses.unfree;
} ''
  mkdir -p $out/lib/firmware
  
  # Copy firmware files, restructuring path to include SHIFT vendor directory
  if [ -d "$baseFw/lib/firmware" ]; then
    cp -r "$baseFw/lib/firmware/"* $out/lib/firmware/ || true
  fi

  chmod -R u+w $out/lib/firmware || true

  if [ -d "$out/lib/firmware/qcom/sdm845/axolotl" ]; then
    mkdir -p "$out/lib/firmware/qcom/sdm845/SHIFT"
    mv "$out/lib/firmware/qcom/sdm845/axolotl" "$out/lib/firmware/qcom/sdm845/SHIFT/"
  fi

  find $out/lib/firmware -type l -name '*.zst' -delete

  # Compress all firmware files to .zst and remove uncompressed originals
  # The kernel will automatically load .zst compressed firmware
  find $out/lib/firmware -type f ! -name '*.zst' -print0 |
    xargs -0 -r -n1 sh -c 'for f; do zstd -q -19 --long=10 -o "$f.zst" "$f" || exit 1; rm -f "$f"; done' sh
''
