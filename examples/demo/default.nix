{ device ? null }:
let
  system-build = import ../../. {
    inherit device;
    configuration = [ (import ./configuration.nix) ];
  };
  burn-tool-build = import ../../. {
    inherit device;
    configuration = [ (import ./android-burn-tool.nix) ];
  };
in
  {
    inherit (system-build.build) android-bootimg android-device vm;
    android-burn-tool = burn-tool-build.build.android-bootimg;
  }
