{ fetchFromGitHub
, lib
, stdenv
}:

stdenv.mkDerivation {
  pname = "karnak-firmware";
  version = "7.0-PS7317";

  src = fetchFromGitHub {
    owner = "mt8163";
    repo = "android_vendor_amazon_karnak";
    rev = "de82805939b832986b26eaf2e78ebe538517c314";
    sha256 = "1pjxdx1y376882a9k3m4wshjc187nmlwllad23mxzrpck04q8wya";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/firmware $out/lib/modules
    cp proprietary/vendor/firmware/* $out/lib/firmware/
    cp proprietary/vendor/lib/modules/* $out/lib/modules/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Proprietary firmware for Amazon Fire HD 8 2018 (karnak)";
    license = licenses.unfree;
    platforms = [ "aarch64-linux" ];
  };
}
