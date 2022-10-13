{ runCommand
, overpass
, roboto
, fira-mono
, font-awesome_5
, nodePackages
}:

let
  artwork = ../../../artwork;
in
runCommand "gui-assets" {
  nativeBuildInputs = [
    nodePackages.svgo
  ];
} ''
mkdir -p $out
cp --no-preserve=mode ${artwork + "/app-background.svg"} $out/app-background.svg
cp --no-preserve=mode ${artwork + "/logo/logo.white.svg"} $out/logo.svg
(
  cd $out
  for f in *.svg; do svgo $f; done
)
mkdir -p $out/fonts
cp -t $out/fonts \
  ${roboto}/share/fonts/truetype/Roboto-Regular.ttf \
  ${overpass}/share/fonts/opentype/overpass-bold.otf \
  ${overpass}/share/fonts/opentype/overpass-extrabold.otf \
  ${fira-mono}/share/fonts/opentype/FiraMono-Regular.otf
cp ${font-awesome_5}/share/fonts/opentype/"Font Awesome 5 Free-Solid-900.otf" $out/fonts/FontAwesome.otf

(
  cd $out/fonts
  ln -s FontAwesome.otf fallback.ttf
)
''
