{ config, lib, pkgs, ... }:

let
  inherit (config) mobile;
  inherit (lib)
    mkOption
    types
  ;
  inherit (mobile.device) identity;
in
{
  options = {
    mobile.outputs.device-metadata = mkOption {
      type = types.package;
      internal = true;
      description = ''
        The device-metadata output is used internally by the documentation
        generation to generate the per-device pages.

        Assume this format is fluid and will change.
      '';
    };
  };

  config.mobile.outputs.device-metadata = pkgs.writeTextFile {
    name = "${mobile.device.name}-metadata";
    destination = "/${mobile.device.name}.json";
    text = (builtins.toJSON {
      inherit (identity) name manufacturer;
      inherit (mobile) hardware;
      inherit (mobile) documentation;
      inherit (mobile.device) supportLevel;
      quirks = {
        inherit (mobile.quirks) supportsStage-0;
      };
      system = {
        inherit (mobile.system) type system;
      };
      identifier = mobile.device.name;
      fullName = "${identity.manufacturer} ${identity.name}";
    });
  };
}
