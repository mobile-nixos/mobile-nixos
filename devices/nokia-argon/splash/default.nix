{ pkgs ? import ../../../pkgs.nix { } }:

let
  fontConfig = pkgs.callPackage (
    { symlinkJoin
    , writeText
    , roboto
    }:
    let
      mkFontsDir = fonts: symlinkJoin { name = "fonts-dir"; paths = fonts; };
      fontsDir = mkFontsDir [
        roboto
      ];
    in

    writeText "fonts.conf" ''
      <?xml version='1.0'?>
      <!DOCTYPE fontconfig SYSTEM 'urn:fontconfig:fonts.dtd'>
      <fontconfig>
        <dir>${fontsDir}</dir>
        <!-- Default rendering settings -->
        <match target="pattern">
          <edit mode="append" name="hinting">
            <bool>true</bool>
          </edit>
          <edit mode="append" name="autohint">
            <bool>true</bool>
          </edit>
          <edit mode="append" name="hintstyle">
            <const>hintslight</const>
          </edit>
          <edit mode="append" name="antialias">
            <bool>true</bool>
          </edit>
        </match>
      </fontconfig>
    ''
  ) { };
in
pkgs.callPackage (

{ runCommandNoCC, fontConfig, ffmpeg, inkscape }:

runCommandNoCC "nokia-argon-splash" {
  FONTCONFIG_FILE = fontConfig;
  nativeBuildInputs = [
    ffmpeg
    inkscape
  ];
} ''
  inkscape --export-type=png --export-area-page --export-filename=splash.png ${./splash.svg}
  ffmpeg \
      -vcodec png \
      -i splash.png \
      -vcodec rawvideo \
      -f rawvideo \
      -pix_fmt bgr565 \
      -s 240x320 \
      -y splash.tmp

  mkdir -p $out
  cat ${./logohdr.bin} splash.tmp > $out/splash.img
  rm splash.tmp
''

) { inherit fontConfig; }
