# This defines the mobile-nixos "overlay" which is
# basically a known channel + this overlay defined
# in overlay.nix.
#
# Every derivations building a boot image and or a
# complete system will import this file somehow.
(import (fetchTarball channel:nixos-unstable)) {
  overlays = [
    (import ./overlay.nix)
  ];
}
