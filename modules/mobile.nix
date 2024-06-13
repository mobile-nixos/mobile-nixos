{ lib, ... }:

let
  inherit (lib)
    mkOption
    types
  ;
in
{
  options = {
    mobile = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          When this setting is set to false, including Mobile
          NixOS in your NixOS configuration should be a no-op.
        '';
      };
      configurationName = mkOption {
        internal = true;
        default = "mobile-nixos";
        description = ''
          Used for some identifiers like the image name.

          This is used in example systems to change the name of the produced
          images.
        '';
      };
    };
  };
}
