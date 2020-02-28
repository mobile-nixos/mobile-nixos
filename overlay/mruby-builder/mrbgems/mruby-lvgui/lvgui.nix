{ stdenv
, lib
, fetchFromGitHub
, pkg-config
, libevdev
, nix-gitignore
, SDL2
, withSimulator ? false
}:

let
  inherit (lib) optional optionals optionalString;
  simulatorDeps = [
    SDL2
  ];
in
  stdenv.mkDerivation {
    pname = "mobile-nixos-early-boot-gui";
    version = "2020-02-05";

    #src = nix-gitignore.gitignoreSource [] ./.;
    src = fetchFromGitHub {
      fetchSubmodules = true;
      repo = "lvgui";
      owner = "mobile-nixos";
      rev = "27ce1511c3c30ed0921fb92504337f1917ab0943";
      sha256 = "1vdahc0lymzprnlckdxcba9p78gqymvsy3bhmyqzjx68r8xcd985";
    };

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs = [
      libevdev
    ]
    ++ optionals withSimulator simulatorDeps
    ;

    NIX_CFLAGS_COMPILE = [
      "-DX_DISPLAY_MISSING"
    ];

    makeFlags = [
    ]
    ++ optional withSimulator "LVGL_ENV_SIMULATOR=1"
    ++ optional (!withSimulator) "LVGL_ENV_SIMULATOR=0"
    ;

    # TODO: `make install`...
    installPhase = ''
      mkdir -p $out/lib
      cp -vr lib*.a $out/lib/

      mkdir -p $out/include
      find . -name '*.h' -exec install -vD '{}' $out/include/'{}' ';'

      mkdir -p $out/lib/pkgconfig
      cat <<EOF > $out/lib/pkgconfig/lvgui.pc
      Name: lvgui
      Description: LVGL-based GUI library
      Version: $version
      Requires: ${optionalString withSimulator "sdl2"}

      Cflags: -I$out/include
      Libs: $out/lib/liblvgui.a
      EOF
    '';

    enableParallelBuilding = true;
  }
