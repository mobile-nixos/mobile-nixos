{ device ? null, pkgs ? null }@args:

import ../../lib/eval-with-configuration.nix (args // {
  configuration = [ (import ./configuration.nix) ];
  additionalHelpInstructions = ''
    The build output to choose depends on the target.

    Pinephone, other u-boot, and depthcharge devices: 

      $ nix-build examples/target-disk-mode --argstr device ${device} -A outputs.default

    Android-based devices:

      $ nix-build examples/target-disk-mode --argstr device ${device} -A outputs.android-bootimg

    App "simulator":

      $ nix-build examples/target-disk-mode --argstr device uefi-x86_64 -A outputs.app-simulator
  '';
})
