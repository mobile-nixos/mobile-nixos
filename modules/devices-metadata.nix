{ config, pkgs, ... }:

let
  inherit (config) mobile;
  inherit (mobile.device) identity;
in
{
  # The device-metadata output is used internally by the documentation
  # generation to generate the per-device pages.
  # Assume this format is fluid and will change.
  system.build.device-metadata = pkgs.writeTextFile {
    name = "${mobile.device.name}-metadata";
    destination = "/${mobile.device.name}.json";
    text = (builtins.toJSON {
      inherit (identity) name manufacturer;
      inherit (mobile) hardware;
      inherit (mobile) documentation;
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
