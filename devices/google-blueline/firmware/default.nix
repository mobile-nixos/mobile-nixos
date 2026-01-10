{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
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

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/firmware
    # Copy firmware, but handle the case where source already has lib/firmware in path
    if [ -d lib/firmware ]; then
      cp -r lib/firmware/* $out/lib/firmware/
    else
      cp -r * $out/lib/firmware/
    fi

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
