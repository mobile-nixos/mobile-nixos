{ stdenv
, lib
, mruby
}:

let
  inherit (lib) concatMapStringsSep;

  # Select libs we need from the libs folder.
  libs = concatMapStringsSep " " (name: "${../../../boot/lib}/${name}") [
    "lvgui/args.rb"
    "lvgui/fiddlier.rb"
    "lvgui/lvgl/*.rb"
    "lvgui/lvgui/*.rb"
    "lvgui/vtconsole.rb"
  ];
in

stdenv.mkDerivation {
  name = "hello-gui.mrb";

  src = lib.cleanSource ./.;

  nativeBuildInputs = [
    mruby
  ];

  buildPhase = ''
    mrbc \
      -o app.mrb \
      ${libs} \
      $(find ./windows -type f -name '*.rb' | sort) \
      main.rb
  '';

  installPhase = ''
    mkdir -p $out/libexec/
    mv -v app.mrb $out/libexec/

    mkdir -p $out/share/hello-gui
  '';
}
