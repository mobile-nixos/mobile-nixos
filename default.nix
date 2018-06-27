# This entry points allows calling `nix-build -A` with
# anything defined in the overlay (or the host system).
{
  device
}:
with import <nixpkgs> {};
let
  # Evaluation doesn't actually use the overlay.
  # The overlay has been re-defined in the modules system.
  eval = import ./lib/eval-config.nix {
    modules = [
      (import (./. + "/devices/${device}" ))
    ]
    # TODO : allow loading from elsewhere through ENV
    ++ lib.optional (builtins.pathExists ./local.nix) (import (./local.nix ))
    ;
  };
in
{
  inherit (eval.config.system.build) all;

  # Shortcut to allow building `nixos` from the same channel revision.
  # This is used by `./nixos/default.nix`
  # Any time `nix-build nixos` is used upstream, it can be used here.
  nixos = (import (path + "/nixos"));
}
