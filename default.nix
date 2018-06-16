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
    ];
  };
in
{
  inherit overlay;
  inherit (eval.config.system.build) all;
}
