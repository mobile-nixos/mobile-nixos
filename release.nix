{ devices ? [ "google-blueline" ] }:

with import <nixpkgs> {};

lib.genAttrs devices ( device: (import ./. { inherit device; }).build.android-bootimg)
