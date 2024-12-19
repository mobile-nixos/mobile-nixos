{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkOption
    types
  ;
in
{
  options.mobile.boot = {
    stage-1.extraUtils = mkOption {
      type = types.listOf (types.either types.attrs types.package);
      description = ''
        Additional packages to be included inside stage-1.

        Do note that *special manipulation* happens and may
        not be compatible with everything.

        The format for extra commands is:
        `{ package = _package_; extraCommand = _extraCommand_ }`

        Where extraCommand is executed at build time, generally
        to fix the package for stage-1 use.
      '';
    };
    stage-1.contents = mkOption {
      type = types.listOf types.attrs;
      default = [];
      description = ''
        Additional files for the initrd.

        See `makeInitrd` for use of `contents`.
      '';
    };
  };
}
