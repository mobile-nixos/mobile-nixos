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
    inherit (system-build.build)
      # Android devices
      android-bootimg android-device
      # QEMU VM
      vm
      # Depthcharge
      disk-image
    ;
    android-burn-tool = burn-tool-build.build.android-bootimg;
  }
