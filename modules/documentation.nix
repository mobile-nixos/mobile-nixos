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
      hydraOutputs = mkOption {
        type = with types; (listOf (listOf str));
        description = "@device@ will be replaced with the device identifer.";
        internal = true;
      };
    };
  };
  config = {
    mobile.documentation.hydraOutputs = lib.mkAfter [
      # x86_64-linux since we link to the cross-compiled build.
      # TODO: link to native builds?
      ["device.@device@.x86_64-linux" "`default` output status"]
    ];
  };
}
