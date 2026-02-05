{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
  zstd,
}:
stdenvNoCC.mkDerivation {
  pname = "firmware-google-blueline";
  version = "unstable-2026-01-03";

  src = fetchFromGitLab {
    owner = "phodina";
    repo = "firmware-google-blueline";
    rev = "c0dd16a522f8c469792681a4ea0017dc58b20b56";
    hash = "sha256-fTbTV74qNQ9FSt78w+mvLF8CKBrThPLO/UhFvXYcO44=";
  };

  nativeBuildInputs = [ zstd ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/firmware
    # Copy firmware only from lib/firmware if present; avoid installing full repo sources
    if [ -d lib/firmware ]; then
      cp -r lib/firmware/* $out/lib/firmware/
    else
      echo "No lib/firmware directory in source; nothing to install."
    fi

    # Remove unwanted large firmware directories
    rm -rf $out/lib/firmware/intel $out/lib/firmware/nvidia $out/lib/firmware/mellanox $out/lib/firmware/mrvl $out/lib/firmware/amdgpu $out/lib/firmware/mediatek || true

    # Compress firmware files to .zst and remove uncompressed originals
    find $out/lib/firmware -type f ! -name '*.zst' -print0 |
      xargs -0 -r -n1 sh -c 'for f; do zstd -q -19 --long=10 --rm "$f" -o "$f.zst" || exit 1; done' sh

    runHook postInstall
  '';

  meta = with lib; {
    description = "Firmware for Google Pixel 3 (Blueline) - SDM845";
    homepage = "https://gitlab.com/phodina/firmware-google-blueline";
    license = licenses.unfree;
    maintainers = with maintainers; [];
    platforms = ["aarch64-linux"];
  };
}
