let
  # Selection of the device can be made either through the environment or through
  # using `--argstr device [...]`.
  deviceFromEnv = builtins.getEnv "MOBILE_NIXOS_DEVICE";

  # Selection of the configuration can by made either through NIX_PATH,
  # through local.nix or as a parameter.
  default_configuration =
    let
      configPathFromNixPath = (builtins.tryEval <mobile-nixos-configuration>).value;
    in
    if configPathFromNixPath != false then [ configPathFromNixPath ]
    else if (builtins.pathExists ./local.nix) then builtins.trace "WARNING: evaluation includes ./local.nix" [ (import ./local.nix) ]
    else []
  ;

  # "a" nixpkgs we're using for its lib.
  pkgs' = import <nixpkgs> {};
  inherit (pkgs'.lib) optional strings;
  inherit (strings) concatStringsSep stringAsChars;
in
{
  pkgs ? import <nixpkgs> {}
  # The identifier of the device this should be built for.
  # (This gets massaged later on)
  # This allows using `default.nix` as a pass-through function.
  # See usage in examples folder.
, device ? null
, configuration ? default_configuration
  # Internally used to tack on configuration by release.nix
, additionalConfiguration ? {}
}:
let
  # Either use:
  #   The given `device`.
  #   The environment variable.
  final_device =
    if device != null then device
    else if deviceFromEnv == "" then
    throw "Please pass a device name or set the MOBILE_NIXOS_DEVICE environment variable."
    else deviceFromEnv
  ;

  inherit (import ./lib/release-tools.nix { inherit pkgs; }) evalWith;

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
  inherit (eval.config.system) build;

  # The evaluated config
  inherit (eval) config;

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
  __please-fail = throw ''
    Cannot directly build for ${final_device}...

    Building this whole set is counter-productive, and not likely to be what
    is desired.

    You can build the `-A build.default` attribute to build an empty and
    un-configured image. That image can be configured using `local.nix`.
    **Note that an unconfigured image may appear to hang at boot.**

    An alternative is to use one of the `examples` system. They differ in their
    configuration. An example that should be building, and working using
    cross-compilation is the `examples/hello` system. Read its README for more
    information.

     $ nix-build examples/hello --argstr device ${final_device} -A build.default

    *************************************************************************
    * Please also read your device's documentation for further usage notes. *
    *************************************************************************
  '';
}
