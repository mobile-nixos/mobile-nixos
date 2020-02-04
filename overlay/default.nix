#
# Allows use of the overlay this way:
#
# ```
# $ nix-build ./overlay -A dtbTool
# $ nix-build --arg crossSystem '(import <nixpkgs/lib>).systems.examples.aarch64-multiplatform' ./overlay -A dtbTool
# ```
#
{
  nixpkgs ? (fetchTarball channel:nixos-unstable)
  , crossSystem ? null
}:
import nixpkgs {
  inherit crossSystem;
  overlays = [
    (import ./overlay.nix)
    (import ./mruby-builder/overlay.nix)
  ];
}
