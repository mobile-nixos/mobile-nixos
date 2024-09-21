# Generated filesystems, contrary to filesystems on a configured system.
#
# This contains the machinery to produce filesystem images.
{ config, lib, pkgs, ...}:

let
  inherit (lib)
    mapAttrs
    mkOption
    types
  ;
in
{
  options = {
    mobile.generatedFilesystems = mkOption {
      type = types.attrsOf (pkgs.image-builder.types.filesystem-image);
      description = ''
        Filesystem definitions that will be created at build.
      '';
    };
    mobile.outputs.generatedFilesystems = mkOption {
      type = with types; attrsOf package;
      internal = true;
      description = ''
        All generated filesystems from the build.
      '';
    };
  };

  config = {
    mobile.outputs.generatedFilesystems =
      mapAttrs (name: config: config.output) config.mobile.generatedFilesystems
    ;
  };
}
