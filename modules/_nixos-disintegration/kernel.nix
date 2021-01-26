# This module replaces the over-zealous `boot.kernelPackages` option
# from `boot/kernel.nix` with one that does not try to override the
# kernel package with arguments that makes the Mobile NixOS kernel
# builder less ergonomic to use.

{ pkgs, lib, config, modulesPath, ... }:

let
  inherit (lib)
    mergeEqualOption
    mkOption
    types
  ;
in
{
  disabledModules = [
    "system/boot/kernel.nix"
  ];

  imports = [
    (
      let
        toOverride = import "${modulesPath}/system/boot/kernel.nix" {
          inherit lib config pkgs;
        };
      in (
        {lib, ...} :
        {
          options = {
            inherit (toOverride.options) system;
            boot = toOverride.options.boot // {
              kernelPackages = mkOption {
                type = types.unspecified // { merge = mergeEqualOption; };
                internal = true;
              };
            };
          };
          inherit (toOverride) config;
        }
      )
    )
  ];
}
