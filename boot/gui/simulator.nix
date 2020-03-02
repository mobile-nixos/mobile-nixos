{ stdenv
, lib
, callPackage
, mrbgems
}:

let
  loader = callPackage ../init {
    mrbgems = mrbgems // {
      mruby-lvgui = callPackage ../../overlay/mruby-builder/mrbgems/mruby-lvgui {
        withSimulator = true;
      };
    };
  };
in
stdenv.mkDerivation {
  pname = "boot-gui-simulator";
  version = "0.0.1";

  src = lib.cleanSource ./.;

  buildInputs = [
    loader.mruby
  ];

  buildPhase = ''
    (PS4=" $ "; set -x
    mrbc -o gui.mrb \
      lib/*.rb main.rb
    )
  '';
  installPhase = ''
    (PS4=" $ "; set -x

    mkdir -p $out/libexec/
    cp -v gui.mrb $out/libexec/gui.mrb

    mkdir -p $out/bin
    cat > $out/bin/simulator <<EOF
     #!/bin/sh
     ${loader}/bin/loader $out/libexec/gui.mrb "\$@"
    EOF
    chmod +x $out/bin/simulator
    )
  '';
}
