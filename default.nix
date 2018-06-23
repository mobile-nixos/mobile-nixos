# This entry points allows calling `nix-build -A` with
# anything defined in the overlay (or the host system).
{
  device
}:
let
  overlay = import ./overlay;
  eval = import ./lib/eval-config.nix {
    pkgs = overlay;
    modules = [
      (import (./. + "/devices/${device}" ))
    ]
    # TODO : allow loading from elsewhere through ENV
    ++ overlay.lib.optional (builtins.pathExists ./local.nix) (import (./local.nix ))
    ;
  };
in
{
  inherit overlay;
  inherit (eval.config.system.build) all;

  # Shortcut to allow building `nixos` from the same channel revision.
  # This is used by `./nixos/default.nix`
  # Any time `nix-build nixos` is used upstream, it can be used here.
  nixos = (import (overlay.path + "/nixos"));
}
