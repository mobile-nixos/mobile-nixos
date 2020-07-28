{ stdenv
, pkgs
, lib
, fetchFromGitHub
, pkg-config
, SDL2
, withSimulator ? false
}:

let
  inherit (lib) optional optionals optionalString;
  simulatorDeps = [
    SDL2
  ];

  # Allow libevdev to cross-compile.
  libevdev = (pkgs.libevdev.override({
    python3 = null;
  })).overrideAttrs({nativeBuildsInputs ? [], ...}: {
    nativeBuildInputs = nativeBuildsInputs ++ [
      pkgs.buildPackages.python3
    ];
  });
in
  stdenv.mkDerivation {
    pname = "lvgui";
    version = "2020-07-25";

    src = fetchFromGitHub {
      fetchSubmodules = true;
      repo = "lvgui";
      owner = "mobile-nixos";
      rev = "aceb8947f2a8d3b4672d30a8e4d74a94f3ded1ac";
      sha256 = "00hcsaljxk08w0jasvqb63h60vak3lrm23b0pygiznbr7xhpm9ci";
    };

    # Document `LVGL_ENV_SIMULATOR` in the built headers.
    # This allows the mrbgem to know about it.
    # (In reality this should be part of a ./configure step or something similar.)
    postPatch = ''
      sed -i"" '/^#define LV_CONF_H/a #define LVGL_ENV_SIMULATOR ${if withSimulator then "1" else "0"}' lv_conf.h
    '';

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
      "PREFIX=${placeholder "out"}"
    ]
    ++ optional withSimulator "LVGL_ENV_SIMULATOR=1"
    ++ optional (!withSimulator) "LVGL_ENV_SIMULATOR=0"
    ;

    enableParallelBuilding = true;
  }
