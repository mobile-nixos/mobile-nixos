{ device ? null
, pkgs ? (import ../../pkgs.nix {})
}@args':
let args = args' // { inherit pkgs; }; in

import ../../lib/eval-with-configuration.nix (args // {
  configuration = [ (import ./configuration.nix) ];
  additionalHelpInstructions = ''
    You can build the `-A outputs.default` attribute to build the default output
    for your device.

     $ nix-build examples/phosh --argstr device ${device} -A outputs.default
  '';
})
