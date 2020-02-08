{ stdenv
, lib
, writeText

, mruby
, buildPackages

, static ? false
}:

let
  inherit (lib) concatStringsSep optional optionalString;
  mruby' = mruby;

  isCross = stdenv.targetPlatform != stdenv.hostPlatform;
  # FIXME: Discover from stdenv rather than from a parameter.
  # (See comment in overlay)
  isStatic = static;
in

# The actual builder function
#
# Given a source, (name or pname/version) and gems, this will automatically
# handle building mruby, then with a stub, 
{ src
, gems ? []
, buildPhase
, ...
}@ attrs:
let
  mruby = mruby'.override({
    inherit gems;
  });
in
  stdenv.mkDerivation ((
    builtins.removeAttrs attrs ["gems"]
  ) // {
  nativeBuildInputs = [
    # For mrbc
    buildPackages.mruby
  ];

  buildPhase = ''
    runHook preBuild

    CFLAGS+=(
      "-I${mruby}/include"
      ${concatStringsSep "\n" mruby.compilerFlags}
    )

    LDFLAGS+=(
      "-L${mruby}/lib"
      ${concatStringsSep "\n" mruby.linkerFlags}
    )

    makeBin() {
      local PS4=" $ "

      local bin="$1"; shift

      echo " :: Compiling ruby code"
      (set -x
      rm -f irep.{c,o}
      mrbc \
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

  installPhase = ":";
})
