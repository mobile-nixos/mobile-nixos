{ device ? null, pkgs ? null }@args:

import ../../lib/eval-with-configuration.nix (args // {
  configuration = [ (import ./configuration.nix) ];
  additionalHelpInstructions = ''
    The build output to choose depends on the target.

    Pinephone, other u-boot, and depthcharge devices: 

      $ nix-build examples/installer --argstr device ${device} -A build.default

    App "simulator":

      $ nix-build examples/installer --argstr device uefi-x86_64 -A build.app-simulator
  '';
})
