{ config, lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options = {
    mobile.documentation = {
      systemTypeFargment = mkOption {
        type = types.path;
        description = "Used to choose the generic documentation fragment for the system.";
        default = ./system-types + "/${config.mobile.system.type}/device-notes.adoc.erb";
        internal = true;
      };
    };
  };
}
