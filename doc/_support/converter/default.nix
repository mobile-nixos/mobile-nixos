{ stdenv, bundlerEnv }:

let
  env =
    bundlerEnv {
    name = "mobile-nixos-process-doc";
    gemdir = ./.;

    exes = [
      "asciidoctor"
    ];

    meta = with stdenv.lib; {
      description = "Custom documentation building pipeline built on asciidoctor";
      license = licenses.mit; # Same as mobile-nixos
      maintainers = with maintainers; [ samueldr ];
      platforms = platforms.unix;
    };
  };
in
  stdenv.mkDerivation {
    name = env.name;
    src = ./.;
    buildInputs = [
      env
      env.wrappedRuby
    ];
    installPhase = ''
      mkdir -vp $out/
      cp -vpr bin $out/
      cp -vpr lib $out/
    '';
  }
