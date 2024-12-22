{ configuration ? null
, ...
}@args:

let
  defaultConfiguration =
    if configuration != null then
      configuration
    else if (builtins.pathExists ./local.nix) then
      builtins.trace ''
        ${"\n"}
        ********************************************
        * WARNING: evaluation includes ./local.nix *
        ********************************************
      '' ./local.nix
    else
      {}
  ;
in

import ./lib/eval-with-configuration.nix (args // {
  configuration = [
    defaultConfiguration
  ];
  additionalHelpInstructions = { device }: ''
    You can build the `-A outputs.default` attribute to build an empty and
    un-configured image. That image can be configured using `local.nix`.

     ** Note that an unconfigured image may appear to hang at boot. **

    An alternative is to use one of the `examples` system. They differ in their
    configuration. An example that should be building, and working using
    cross-compilation is the `examples/hello` system. Read its README for more
    information.

     $ nix-build examples/hello --argstr device ${device} -A outputs.default
  '';
})
