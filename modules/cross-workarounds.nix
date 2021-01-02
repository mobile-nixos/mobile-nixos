{ config, lib, pkgs, ... }:

# This module adds system-level workarounds when cross-compiling.
# These workarounds are only expected to be implemented for the *basic* build.
# That is `nix-build ./default.nix`, without additional configuration.
let
  isCross =
    config.nixpkgs.crossSystem != null &&
    config.nixpkgs.localSystem.system != null &&
    config.nixpkgs.crossSystem.system != config.nixpkgs.localSystem.system;

  AArch32Overlay = final: super: {
    # Works around libselinux failure with python on armv7l.
    # LONG_BIT definition appears wrong for platform
    libselinux = (super.libselinux
      .override({
        enablePython = false;
      }))
      .overrideAttrs (_: {
        preInstall = ":";
      })
    ;
  };
in
lib.mkIf isCross
{
  # building '/nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-fc-cache.drv'...
  # [...]-fontconfig-2.10.2-aarch64-unknown-linux-gnu-bin/bin/fc-cache: cannot execute binary file: Exec format error
  fonts.fontconfig.enable = false;

  # building '/nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-mesa-19.3.3-aarch64-unknown-linux-gnu.drv'...
  # meson.build:1537:2: ERROR: Dependency "wayland-scanner" not found, tried pkgconfig
  security.polkit.enable = false;

  # udisks fails due to gobject-introspection being not cross-compilation friendly.
  services.udisks2.enable = false;

  nixpkgs.overlays = lib.mkMerge [
    (lib.mkIf config.nixpkgs.crossSystem.isAarch32 [ AArch32Overlay ])
  ];
}
