# https://gitlab.com/postmarketOS/pmaports/-/blob/8bc434515fa34743ac060a313b0137fed681e1f5/main/mtk-mkimage/APKBUILD
# 
# This is a free implementation of a binary named "mkimage" in MediaTek kernel trees.

{ stdenvNoCC
, lib
, fetchurl
}:

stdenvNoCC.mkDerivation {
  pname = "mtk-mkimage";
  version = "2018-06-15";

  src = fetchurl {
    url = "https://gist.githubusercontent.com/ollieparanoid/6eaaba3d520cf938cee10c72eb31f0a8/raw/80ba45e32e358935a11083e7a847ce582906961a/mtk_mkimage.sh";
    sha256 = "sha256-Cqgs012FGIhOiFF9A7lpj9DEIRqeQKKXtfSZR9zqfT4=";
  };

  dontUnpack = true;

  installPhase = ''
    install -Dm755 $src $out/bin/mtk-mkimage
  '';

  meta = with lib; {
    description = "Prepend MediaTek header to boot.img files for MediaTek devices";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ zhaofengli ];
  };
}
