# Ensure CLI passes down arguments
{ ... }@args:

import ../../lib/eval-with-configuration.nix (args // {
  configuration = [ (import ./configuration.nix) ];
  additionalHelpInstructions = { device }: ''
    The build output to choose depends on the target.

    Pinephone, other u-boot, and depthcharge devices: 

      $ nix-build examples/installer --argstr device ${device} -A outputs.default

    App "simulator":

      $ nix-build examples/installer --argstr device uefi-x86_64 -A ouptuts.app-simulator
  '';
})
