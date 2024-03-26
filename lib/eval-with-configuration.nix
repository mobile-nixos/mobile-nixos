# This is a shim that calls `evalWithConfiguration` automatically, with
# some additional helpers.
# This replaces the previously quite un-hermetic `default.nix` inclusion.
# This is meant for use internally by Mobile NixOS, the interface here
# should not be assumed to be *stable*.
{
  pkgs ? null
  # The identifier of the device this should be built for.
  # (This gets massaged later on)
, device ? null
, configuration
  # Internally used to tack on configuration by release.nix
, additionalConfiguration ? {}
, additionalHelpInstructions ? ""
}:
if pkgs == null then (builtins.throw "The `pkgs` argument needs to be provided to eval-with-configuration.nix") else
let
  inherit (pkgs.lib) optionalString strings;
  inherit (strings) concatStringsSep stringAsChars;

  # Either use:
  #   The given `device`.
  #   The environment variable.
  final_device =
    if device != null then device
    else throw "Please provide a device name using e.g. `--argstr device $DEVICE`."
  ;

  inherit (import ./release-tools.nix { inherit pkgs; }) evalWith;

  # The "default" eval.
  eval = evalWith {
    device = final_device;
    modules = configuration;
    inherit additionalConfiguration;
  };

  # Makes a mostly useless header.
  # This is mainly useful for batch evals.
  header = str:
    let
      str' = "* ${str} *";
      line = stringAsChars (x: "*") str';
    in
    builtins.trace (concatStringsSep "\ntrace: " [line str' line])
  ;

  # Merge the system-type outputs at the root of the outputs.
  outputs = eval.config.mobile.outputs // eval.config.mobile.outputs.${eval.config.mobile.system.type};
in
  (
    # Don't break if `device` is not set.
    if device == null then (id: id) else
    if device ? special
    then header "Evaluating: ${device.name}"
    else if (builtins.tryEval (builtins.isPath device && builtins.pathExists device)).value
    then header "Evaluating device from path: ${toString device}"
    else header "Evaluating device: ${device}"
  )
{
  # The build artifacts from the modules system.
  inherit outputs;

  # The evaluated config
  inherit (eval) config;
  inherit (eval) options;

  # The final pkgs set, usable as -A pkgs.[...] on the CLI.
  inherit (eval) pkgs;

  # The whole (default) eval
  inherit eval;

  # Evaluating this whole set is counter-productive.
  # It'll put a *bunch* of build products from the misc. inherits we added.

  # (We're also using `device` to force the other throw to happen first.)
  # TODO : We may want to produce an internal list of available outputs, so that
  #        each platform can document what it makes available. This would allow
  #        the message to be more user-friendly by displaying a choice.
  #        Something like `config.mobile.build.proposedOutputs` as a list of pairs [ "outputName" "description" ].
  __please-fail = throw ''
    Cannot directly build for ${final_device}...

    Building this whole set is counter-productive, and not likely to be what
    is desired.
    ${optionalString (additionalHelpInstructions != "") "\n"}${additionalHelpInstructions}
    *************************************************
    * Please also read your device's documentation. *
    *      It may contain further usage notes.      *
    *************************************************
  '';
}
