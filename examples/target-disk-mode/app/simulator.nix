{ stdenv
, lib
, callPackage
, mrbgems
, mruby
, mobile-nixos
, input-utils
}:

let
  script-loader = mobile-nixos.stage-1.script-loader.override({
    withSimulator = true;
  });
  applet = callPackage ./. {};
in
(script-loader.wrap {
  name = "simulator";
  applet = "${applet}/libexec/app.mrb";
  env = {
    PATH = "${input-utils}/bin:$PATH";
  };
}).overrideAttrs(old: rec {
  pname = "tdm-gui-simulator";
  version = "0.0.1";
  name = "${pname}-${version}";
})
