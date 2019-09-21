# Selection of the device can be made either through the environment or through
# using `--argstr device [...]`.
let deviceFromEnv = builtins.getEnv "MOBILE_NIXOS_DEVICE"; in

{ pkgs' ? import <nixpkgs> {}
, device ?
    if deviceFromEnv == ""
    then throw "Please pass a device name or set the MOBILE_NIXOS_DEVICE environment variable."
    else deviceFromEnv
}:
let
  inherit (pkgs'.lib) optional;
  inherit (pkgs') path;

  eval = import ./lib/eval-config.nix {
    modules = [
      (import (./. + "/devices/${device}" ))
    ]
    # TODO : allow loading from elsewhere through ENV
    ++ optional (builtins.pathExists ./local.nix) (import (./local.nix ))
    ;
  };
in
{
  inherit (eval.config.system.build) all;
  inherit (eval) config pkgs;
  inherit (eval.pkgs) lib;
  inherit eval;

  # Shortcut to allow building `nixos` from the same channel revision.
  # This is used by `./nixos/default.nix`
  # Any time `nix-build nixos` is used upstream, it can be used here.
  nixos = (import (path + "/nixos"));
}
