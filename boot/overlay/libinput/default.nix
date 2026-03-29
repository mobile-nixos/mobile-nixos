{ libinput
, libevdev
, mtdev
, buildPackages
}:
(libinput.override {
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
})
.overrideAttrs({ nativeBuildInputs ? [], mesonFlags, ... }: {
  buildInputs = [
    libevdev
    mtdev
  ];
  nativeBuildInputs = nativeBuildInputs ++ [
    buildPackages.udev
  ];
  mesonFlags = mesonFlags ++ [
    "-Dlibwacom=false"
  ];
})
