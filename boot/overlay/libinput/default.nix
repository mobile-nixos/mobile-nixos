{ lib
, libinput
, libevdev
, mtdev
, buildPackages
}:
(libinput.override ({
    libwacom = null;
    documentationSupport = false;
    doxygen = null;
    graphviz = null;
    eventGUISupport = false;
    cairo = null;
    glib = null;
    gtk3 = null;
    testsSupport = false;
    check = null;
    valgrind = null;
    python3 = null;
  }
  // lib.optionalAttrs (lib.functionArgs libinput.override ? lua5_4) { lua5_4 = null; }
))
.overrideAttrs({ nativeBuildInputs ? [], mesonFlags, ... }: {
  buildInputs = [
    libevdev
    mtdev
  ];
  nativeBuildInputs = nativeBuildInputs ++ [
    buildPackages.udev
  ];
  mesonFlags = mesonFlags ++ [
    (lib.mesonBool "libwacom" false)
    (lib.mesonEnable "lua-plugins" false)
  ];
})
