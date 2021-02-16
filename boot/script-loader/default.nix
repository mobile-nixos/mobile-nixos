{ fetchurl
, mruby
, mrbgems
, writeShellScriptBin
, lib
, callPackage

# Configuration
, withSimulator ? false      # Builds lvgui with simulator.
}:

let
  mruby' = mruby.override({
    # This script loader handles all "applets" and scripts that will run during
    # stage-1.
    gems = with mrbgems; [
      { core = "mruby-exit"; }
      { core = "mruby-io"; }
      { core = "mruby-sleep"; }
      { core = "mruby-time"; }
      mruby-dir
      mruby-dir-glob
      mruby-env
      mruby-file-stat
      mruby-json
      mruby-logger
      mruby-open3
      mruby-process-clock_gettime
      mruby-regexp-pcre
      mruby-singleton
      mruby-time-strftime
      mruby-zmq

      # Glue that serves to link the proper dependencies into the project.
      mruby-lvgui-native-fragment

      # Though this needs to be the real last gem, as it has
      # special significance during the build.
      mruby-require
    ];
  });
  mruby-lvgui-native-fragment = callPackage ./mruby-lvgui-native-fragment {
    inherit withSimulator;
  };
in
# We need a reference to this package for the passthru `wrap` helper.
let loader = mruby'.builder {
  pname = "mobile-nixos-script-loader";
  version = "0.2.0";

  src = ./.;

  # `main.rb` is where the magic happens.
  buildPhase = ''
    makeBin loader main.rb
  '';

  passthru = {
    # Wraps an `mrb` applet into a runner script that uses this loader.
    # Note that this is not used in stage-1.
    # NOTE: `env` escapes values using `builtins.toJSON`. This escapes some pitfalls, while keeping variables expandable.
    wrap = {name, applet, env ? {}}: (writeShellScriptBin name ''
      ${let
        varList = lib.attrsets.mapAttrsToList (name: value: "${name}=${builtins.toJSON value}") env;
        scriptEnv = lib.strings.concatStringsSep "\n" varList;
      in scriptEnv}
      exec ${loader}/bin/loader ${applet} "$@"
    '').overrideAttrs(old: {
      passthru = {
        inherit applet;
      };
    });
  };
};
in loader
