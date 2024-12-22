# Ensure CLI passes down arguments
{ ... }@args:

import ../../lib/eval-with-configuration.nix (args // {
  configuration = [ (import ./configuration.nix) ];
  additionalHelpInstructions = { device }: ''
    You can build the `-A outputs.default` attribute to build the default output
    for your device.

     $ nix-build examples/hello --argstr device ${device} -A outputs.default
  '';
})
