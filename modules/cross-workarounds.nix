{ lib, config, ... }:

# This module adds system-level workarounds when cross-compiling.
# These workarounds are only expected to be implemented for the *basic* build.
# That is `nix-build ./default.nix`, without additional configuration.
let
  isCross =
    config.nixpkgs.crossSystem != null &&
    config.nixpkgs.localSystem.system != null &&
    config.nixpkgs.crossSystem.system != config.nixpkgs.localSystem.system;
in
lib.mkIf isCross
{
  # building '/nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-fc-cache.drv'...
  # [...]-fontconfig-2.10.2-aarch64-unknown-linux-gnu-bin/bin/fc-cache: cannot execute binary file: Exec format error
  fonts.fontconfig.enable = false;

  # building '/nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-mesa-19.3.3-aarch64-unknown-linux-gnu.drv'...
  # meson.build:1537:2: ERROR: Dependency "wayland-scanner" not found, tried pkgconfig
  security.polkit.enable = false;
}
