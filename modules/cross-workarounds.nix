{ config, lib, pkgs, ... }:

# This module adds system-level workarounds when cross-compiling.
# These workarounds are only expected to be implemented for the *basic* build.
# That is `nix-build ./default.nix`, without additional configuration.
let
  isCross =
    config.nixpkgs.crossSystem != null &&
    config.nixpkgs.localSystem.system != null &&
    config.nixpkgs.crossSystem.system != config.nixpkgs.localSystem.system;
  nullPackage = pkgs.runCommand "null" {} ''
    mkdir -p $out
  '';
in
lib.mkIf isCross (lib.mkMerge [

# All cross-compilation
{
  # No workarounds needed!
}

# 32 bit ARM
(lib.mkIf config.nixpkgs.crossSystem.isAarch32 {
  nixpkgs.overlays = [
    (final: super:
      # Ensure pkgsBuildBuild ends up unmodified, otherwise the canary test will
      # get super expensive to build.
      if super.stdenv.buildPlatform == super.stdenv.hostPlatform
      then {}
      else {
        # btrfs-progs-armv7l-unknown-linux-gnueabihf-5.17.drv
        # /nix/store/wnrc4daqbd6v5ifqlxsj75ky8556zy0p-python3-3.9.12/include/python3.9/pyport.h:741:2: error: #error "LONG_BIT definition appears wrong for platform (bad gcc/glibc config?)."
        btrfs-progs = lib.warn "btrfs-progs neutered due to broken build with cross armv7l" nullPackage;
      }
    )
  ];
})

])
