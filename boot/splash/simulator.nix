{ mobile-nixos
, callPackage
}:

let
  script-loader = mobile-nixos.stage-1.script-loader.override({
    withSimulator = true;
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
