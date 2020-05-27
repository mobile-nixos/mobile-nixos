{ stdenv
, lib
, mruby
}:

stdenv.mkDerivation {
  name = "hello-gui.mrb";

  src = lib.cleanSource ./.;

  nativeBuildInputs = [
    mruby
  ];

  buildPhase = ''
    mrbc -g -o app.mrb \
      $(find ${../../../boot/gui/lib} -type f -name '*.rb' | sort) \
      $(find ./lib -type f -name '*.rb' | sort) \
      main.rb
  '';

  installPhase = ''
    mkdir -p $out/libexec/
    mv -v app.mrb $out/libexec/

    mkdir -p $out/share/hello-gui
  '';
}
