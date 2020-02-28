final: super:

let
  # Errr... nothing in the `makeStatic*` stdenv adapters allow detecting
  # whether we're doing a static build or not in a sane manner.
  # Let's co-opt the `dontDisableStatic` attribute it overrides into a
  # derivation, let's say, hello...
  static = if final.hello ? dontDisableStatic then final.hello.dontDisableStatic else false;
  mrbgems = final.callPackage ./mrbgems {};
in
{
  hello-mruby = final.callPackage ./hello-mruby {};
  mrbgems = mrbgems // {
    mruby-lvgui = final.callPackage ./mrbgems/mruby-lvgui {
      mrbgems = mrbgems;
    };
  };
  mruby = (final.callPackage ./mruby {}).overrideAttrs({passthru ? {}, ...}: {
    passthru = passthru // {
      builder = final.callPackage ./mruby/builder.nix {
    	inherit static;
      };
    };
  });
}
