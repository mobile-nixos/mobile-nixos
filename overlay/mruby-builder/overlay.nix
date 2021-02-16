final: super:

let
  # Errr... nothing in the `makeStatic*` stdenv adapters allow detecting
  # whether we're doing a static build or not in a sane manner.
  # Let's co-opt the `dontDisableStatic` attribute it overrides into a
  # derivation, let's say, hello...
  static = if final.hello ? dontDisableStatic then final.hello.dontDisableStatic else false;
in
{
  hello-mruby = final.callPackage ./hello-mruby {};
  mrbgems = final.callPackage ./mrbgems {};
  mruby = final.callPackage ./mruby {
    builder = final.callPackage ./mruby/builder.nix {
      inherit static;
    };
  };
}
