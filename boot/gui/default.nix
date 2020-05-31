{ stdenv
, lib
, mruby
}:

stdenv.mkDerivation {
  name = "boot-gui.mrb";

  src = lib.cleanSource ./.;

  nativeBuildInputs = [
    mruby
  ];

  buildPhase = ''
    mrbc -g -o gui.mrb \
      $(find lib -type f -name '*.rb' | sort) \
      main.rb
  '';

  installPhase = ''
    mv -v gui.mrb $out
  '';
}
