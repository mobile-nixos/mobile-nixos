# All otions defined here are *extremely internal*.
# **Do not** set them in your configuration.
# **Do not** rely on them existing.
{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options = {
    mobile._internal = {
      compressLargeArtifacts = mkOption {
        type = types.bool;
        default = false;
        internal = true;
      };
    };
  };
}
