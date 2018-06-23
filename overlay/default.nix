# This defines the mobile-nixos "overlay" which is
# basically a known channel + this overlay defined
# in overlay.nix.
#
# Every derivations building a boot image and or a
# complete system will import this file somehow.
let
  nixpkgs = import (fetchTarball channel:nixos-unstable);
in
nixpkgs {
  crossSystem = (nixpkgs {}).lib.systems.examples.aarch64-multiplatform;
  overlays = [
    (import ./overlay.nix)
  ];
}
