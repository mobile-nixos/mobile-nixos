final: super:

{
  hello-mruby = final.callPackage ./hello-mruby {};
  mrbgems = final.callPackage ./mrbgems {};
  mruby = final.callPackage ./mruby {
    builder = final.callPackage ./mruby/builder.nix { };
  };
}
