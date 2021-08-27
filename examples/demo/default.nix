{ device ? null, pkgs ? null }@args:

import ../../lib/eval-with-configuration.nix (args // {
  configuration = [ (import ./configuration.nix) ];
  additionalHelpInstructions = ''
    You can build the `-A outputs.default` attribute to build the default output
    for your device.

     $ nix-build examples/demo --argstr device ${device} -A outputs.default
  '';
})
