{ device ? null }:
let
  burn-tool-build = import ../../. {
    inherit device;
    configuration = [ (import ./android-burn-tool.nix) ];
  };
in
  {
    android-burn-tool = burn-tool-build.build.android-bootimg;
  }
