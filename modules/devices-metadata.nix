{ config, pkgs, ... }:

let
  inherit (config) mobile;
  inherit (mobile.device) info;
in
{

  # The device-metadata output is used internally by the documentation
  # generation to generate the per-device pages.
  # Assume this format is fluid and will change.
  system.build.device-metadata = pkgs.writeTextFile {
    name = "${mobile.device.name}-metadata";
    destination = "/${mobile.device.name}.json";
    text = (builtins.toJSON {
      inherit (info) name;
      inherit (mobile) hardware;
      system = {
        inherit (mobile.system) type system;
      };

      manufacturer = if info ? manufacturer then info.manufacturer else "N/A";
      identifier = mobile.device.name;

      fullName = if info ? manufacturer
        then "${info.manufacturer} ${info.name}"
        else info.name;
    });
  };
}
