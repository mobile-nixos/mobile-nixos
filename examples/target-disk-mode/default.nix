{ device }:

let
  system-build = import ../../. {
    inherit device;
    configuration = [ (import ./configuration.nix) ];
  };
in
{
  inherit (system-build) build;
}
