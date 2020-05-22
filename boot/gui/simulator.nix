{ stdenv
, lib
, callPackage
, mrbgems
, mruby
}:

let
  loader = callPackage ../script-loader {
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

  nativeBuildInputs = [
    mruby
  ];

  buildPhase = ''
    (PS4=" $ "; set -x
    mrbc -g -o gui.mrb \
      $(find lib -type f -name '*.rb' | sort) \
      main.rb
    )
  '';
  installPhase = ''
    (PS4=" $ "; set -x

    mkdir -p $out/libexec/
    cp -v gui.mrb $out/libexec/gui.mrb

    mkdir -p $out/bin
    cat > $out/bin/simulator <<EOF
      #!/bin/sh
      args=()
      if [[ -n "\$DEBUGGER" ]]; then
        args+=(\$DEBUGGER)
      fi
      args+=(
        ${loader}/bin/loader
        $out/libexec/gui.mrb
        "\$@"
      )
      exec "\''${args[@]}"
    EOF
    chmod +x $out/bin/simulator
    )
  '';
}
