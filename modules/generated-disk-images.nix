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
    mobile.generatedDiskImages = mkOption {
      type = types.attrsOf (pkgs.image-builder.types.disk-image);
      description = lib.mdDoc ''
        Disk image definitions that will be created at build.
      '';
    };
    mobile.outputs.generatedDiskImages = mkOption {
      type = with types; attrsOf package;
      internal = true;
      description = lib.mdDoc ''
        All generated disk images from the build.
      '';
    };
  };

  config = {
    mobile.outputs.generatedDiskImages =
      mapAttrs (name: config: config.output) config.mobile.generatedDiskImages
    ;
  };
}
