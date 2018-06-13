{
  pkgs,
  lib,
  ...
}:
let
  config = (lib.importJSON ../postmarketOS-devices.json).asus-z00t;
  msm-fb-refresher = (import ../../quirks/qualcomm/msm-fb-refresher.nix) { inherit pkgs lib; };
in
config // {
  name = config.pm_name;
  kernel = pkgs.callPackage ./kernel { kernelPatches = pkgs.defaultKernelPatches; };

  stage-1 = {
    fb_modes = ./fb.modes;
    inherit (msm-fb-refresher.stage-1) initFramebuffer;
    packages = with pkgs; [
      strace
    ]
    ++ msm-fb-refresher.stage-1.packages
    ;
  };
}
