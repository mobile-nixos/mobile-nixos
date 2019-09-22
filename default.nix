# Selection of the device can be made either through the environment or through
# using `--argstr device [...]`.
let deviceFromEnv = builtins.getEnv "MOBILE_NIXOS_DEVICE"; in

{
  # "a" nixpkgs we're using for its lib.
  pkgs' ? import <nixpkgs> {}

  # The identifier of the device this should be built for.
, device ?
    if deviceFromEnv == ""
    then throw "Please pass a device name or set the MOBILE_NIXOS_DEVICE environment variable."
    else deviceFromEnv
}:
let
  inherit (pkgs'.lib) optional;

  # Evaluates NixOS, mobile-nixos and the device config with the given
  # additional modules.
  evalWith = modules: import ./lib/eval-config.nix {
    modules = [
      (import (./. + "/devices/${device}" ))
    ] ++ modules;
  };

  # Eval with `local.nix` if available.
  # This eval is the "WIP" eval. What's usually built with `nix-build`.
  eval = evalWith (optional (builtins.pathExists ./local.nix) (import (./local.nix )));
in
{
  # The build artifacts from the modules system.
  inherit (eval.config.system) build;

  # The evaluated config
  inherit (eval) config;

  # The final pkgs set, usable as -A pkgs.[...] on the CLI.
  inherit (eval) pkgs;

  # The whole (default) eval
  inherit eval;

  # Shortcut to allow building `nixos` from the same channel revision.
  # This is used by `./nixos/default.nix`
  # Any time `nix-build nixos` is used upstream, it can be used here.
  nixos = import <nixpkgs/nixos>;

  # Evaluating this whole set is counter-productive.
  # It'll put a *bunch* of build products from the misc. inherits we added.

  # (We're also using `device` to force the other throw to happen first.)
  # TODO : We may want to produce an internal list of available outputs, so that
  #        each platform can document what it makes available. This would allow
  #        the message to be more user-friendly by displaying a choice.
  __please-fail = throw ''
    Cannot directly build for ${device}...

    Building this whole set is counter-productive, and not likely to be what
    is desired.

    Please refer to your platform's documentation for usage.
  '';
}
