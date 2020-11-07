{ stdenv
, lib
, callPackage
, mrbgems
, mruby
, mobile-nixos
}:

let
  script-loader = mobile-nixos.stage-1.script-loader.override({
    mrbgems = mrbgems // {
      mruby-lvgui = callPackage ../../overlay/mruby-builder/mrbgems/mruby-lvgui {
        withSimulator = true;
      };
    };
  });
  applet = callPackage ./. {};
in
(script-loader.wrap {
  name = "simulator";
  inherit applet;
}).overrideAttrs(old: rec {
  pname = "boot-splash-simulator";
  version = "0.0.1";
  name = "${pname}-${version}";
})
