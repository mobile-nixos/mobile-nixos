# Ensure CLI passes down arguments
{ ... }@args:

let
  eval = import ../../lib/eval-with-configuration.nix (args // {
    configuration = [
      (
        { config, lib, ... }:
        let
          inherit (lib)
          filter
          concatStringsSep
          showWarnings
          ;
          # Handle assertions and warnings
          failedAssertions = map (x: x.message) (filter (x: !x.assertion) config.assertions);

          # This `eval` wraps assertion checks
          _out = if failedAssertions != []
            then throw "\nFailed assertions:\n${concatStringsSep "\n" (map (x: "- ${x}") failedAssertions)}"
            else showWarnings config.warnings { inherit config; };
        in
        {
          imports = [
            ./configuration.nix
          ];
          options = {
            _out = lib.mkOption {
            };
          };
          config = {
            inherit _out;
          };
        }
      )
    ];
  });
in
  eval.config._out
