{ device ? null, configuration ? null, pkgs ? null }@args:

let
  # Selection of the configuration can by made either through NIX_PATH,
  # through local.nix or as a parameter.
  defaultConfiguration =
    let
      configPathFromNixPath = (builtins.tryEval <mobile-nixos-configuration>).value;
    in
    if configPathFromNixPath != false then
      [ configPathFromNixPath ]
    else if configuration != null then
      [ configuration ]
    else if (builtins.pathExists ./local.nix) then
      builtins.trace ''
        ${"\n"}
        ********************************************
        * WARNING: evaluation includes ./local.nix *
        ********************************************
      '' [ (import ./local.nix) ]
    else
      []
  ;
in

import ./lib/eval-with-configuration.nix (args // {
  configuration = defaultConfiguration;
  additionalHelpInstructions = ''
    You can build the `-A build.default` attribute to build an empty and
    un-configured image. That image can be configured using `local.nix`.

     ** Note that an unconfigured image may appear to hang at boot. **

    An alternative is to use one of the `examples` system. They differ in their
    configuration. An example that should be building, and working using
    cross-compilation is the `examples/hello` system. Read its README for more
    information.

     $ nix-build examples/hello --argstr device ${device} -A build.default
  '';
})
