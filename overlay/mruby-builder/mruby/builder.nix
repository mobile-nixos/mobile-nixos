{ stdenv
, lib
, writeText

, mruby
, buildPackages
}:

let
  inherit (lib) optionalString;

in

# The actual builder function
#
# Given a source, (name or pname/version) and gems, this will automatically
# handle building mruby, then with a stub, 
{ src
, buildPhase
, passthru ? {}
, nativeBuildInputs ? []
, ...
}@ attrs:

# `gems` is not a valid argument for `mruby.builder` anymore.
assert attrs ? gems == false;

  stdenv.mkDerivation ((
    builtins.removeAttrs attrs ["gems"]
  ) // {
  nativeBuildInputs = [
    # For mrbc
    buildPackages.mruby
  ] ++ nativeBuildInputs;

  buildInputs = mruby.buildInputs;

  buildPhase = ''
    runHook preBuild

    . ${mruby}/nix-support/mruby_linker_flags.sh

    CFLAGS+=(
      "-I${mruby}/include"
      "''${mrb_cflags[@]}"
    )

    LDFLAGS+=(
      "-L${mruby}/lib"
      "-lmruby"
      "''${mrb_linker_flags[@]}"
      "''${mrb_linker_flags_before_libraries[@]}"
      "''${mrb_linker_library_paths_flags[@]}"
      "''${mrb_linker_libraries_flags[@]}"
      "''${mrb_linker_flags_after_libraries[@]}"
    )

    makeBin() {
      local PS4=" $ "

      local bin="$1"; shift

      echo " :: Compiling ruby code"
      (set -x
      rm -f irep.{c,o}
      mrbc \
        ${optionalString mruby.debug "-g"} \
        -Bruby_irep \
        -oirep.c \
        "$@"
      )

      [ ! -f stub.c ] && cp -f ${./stub.c} stub.c

      echo " :: Compiling with stub"
      (set -x
      $CC \
        ''${CFLAGS[@]} \
        ./stub.c \
        ''${LDFLAGS[@]} \
        -o $bin
      )
      cp $bin $out/bin/
    }

    mkdir -p $out/bin

    echo "Running user buildPhase"

    ${buildPhase}

    runHook postBuild
  '';

  passthru = passthru // {
    inherit mruby;
  };

  installPhase = ":";
})
